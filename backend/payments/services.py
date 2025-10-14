"""
Payment verification services using Grok API.
"""
import requests
import base64
import json
import logging
from datetime import datetime, timedelta
from django.conf import settings
from django.utils import timezone
from decimal import Decimal

logger = logging.getLogger('payments')


class GrokPaymentVerifier:
    """
    Service to verify SINPE Móvil payment receipts using Grok API (xAI).
    """

    def __init__(self):
        self.api_key = settings.GROK_API_KEY
        self.api_url = settings.GROK_API_URL
        self.timeout = 30

    def verify_receipt(self, receipt, order):
        """
        Verify payment receipt using Grok vision capabilities.

        Args:
            receipt (PaymentReceipt): Payment receipt object
            order (Order): Associated order

        Returns:
            dict: Verification results with extracted data and verification status
        """
        try:
            # Read and encode image
            with receipt.receipt_image.open('rb') as img_file:
                img_base64 = base64.b64encode(img_file.read()).decode()

            # Prepare verification prompt
            prompt = self._create_verification_prompt(order)

            # Call Grok API
            response_data = self._call_grok_api(img_base64, prompt)

            # Process and validate results
            verification_result = self._process_verification_result(
                response_data,
                order
            )

            logger.info(
                f"Receipt verification completed for order {order.order_number}: "
                f"Verified={verification_result['verified']}, "
                f"Confidence={verification_result['confidence']}%"
            )

            return verification_result

        except Exception as e:
            logger.error(f"Error verifying receipt for order {order.order_number}: {e}", exc_info=True)
            return {
                'verified': False,
                'confidence': 0,
                'extracted_data': {},
                'issues': [f'Error en verificación: {str(e)}']
            }

    def _create_verification_prompt(self, order):
        """Create the verification prompt for Grok."""
        expected_amount = float(order.total)
        expected_receiver = order.seller.seller_profile.sinpe_number

        # Clean phone number format
        if not expected_receiver.startswith('+'):
            expected_receiver = f"+506{expected_receiver}"

        prompt = f"""
Eres un asistente especializado en verificar comprobantes de pago SINPE Móvil de Costa Rica.

Analiza esta imagen de comprobante de SINPE Móvil y extrae la siguiente información:

1. **Monto transferido** (en colones costarricenses, CRC)
2. **Número de teléfono del receptor** (quien recibe el dinero)
3. **Número de teléfono del emisor** (quien envía el dinero)
4. **ID o número de transacción**
5. **Fecha y hora de la transacción**
6. **Nombre del banco o entidad financiera**

CRITERIOS DE VERIFICACIÓN:
- El monto debe ser EXACTAMENTE ₡{expected_amount:,.2f} colones
- El número de teléfono del receptor debe ser {expected_receiver}
- La transacción debe ser reciente (máximo 1 hora desde ahora)

IMPORTANTE:
- Los números de teléfono pueden estar en formato +506XXXXXXXX o solo XXXXXXXX
- El monto puede tener separadores de miles (comas o puntos)
- Busca términos como "Transferencia exitosa", "SINPE", "Móvil", etc.

Responde ÚNICAMENTE con un objeto JSON válido en este formato exacto:
{{
    "amount": "monto extraído como número decimal",
    "receiver_phone": "número del receptor con código de país",
    "sender_phone": "número del emisor con código de país",
    "transaction_id": "ID de transacción",
    "transaction_date": "fecha en formato ISO 8601",
    "bank": "nombre del banco",
    "verified": true o false (si cumple TODOS los criterios),
    "confidence": número del 0 al 100,
    "issues": ["lista de problemas encontrados, vacía si no hay problemas"]
}}

Si no puedes leer la imagen o no es un comprobante SINPE válido, establece verified=false, confidence=0 y describe los problemas en issues.
"""
        return prompt

    def _call_grok_api(self, image_base64, prompt):
        """
        Call Grok API with the image and prompt.

        Args:
            image_base64 (str): Base64 encoded image
            prompt (str): Verification prompt

        Returns:
            dict: Parsed JSON response from Grok
        """
        headers = {
            'Authorization': f'Bearer {self.api_key}',
            'Content-Type': 'application/json'
        }

        payload = {
            'model': 'grok-vision-beta',  # Adjust based on actual Grok model name
            'messages': [
                {
                    'role': 'user',
                    'content': [
                        {'type': 'text', 'text': prompt},
                        {
                            'type': 'image_url',
                            'image_url': {
                                'url': f'data:image/jpeg;base64,{image_base64}'
                            }
                        }
                    ]
                }
            ],
            'temperature': 0.1,  # Low temperature for consistent extraction
            'max_tokens': 1000,
        }

        try:
            response = requests.post(
                f'{self.api_url}/chat/completions',
                headers=headers,
                json=payload,
                timeout=self.timeout
            )
            response.raise_for_status()

            result = response.json()
            content = result['choices'][0]['message']['content']

            # Extract JSON from response (in case there's extra text)
            # Try to find JSON object in the response
            start_idx = content.find('{')
            end_idx = content.rfind('}') + 1

            if start_idx != -1 and end_idx > start_idx:
                json_str = content[start_idx:end_idx]
                return json.loads(json_str)
            else:
                # If no JSON found, try parsing entire content
                return json.loads(content)

        except requests.exceptions.RequestException as e:
            logger.error(f"Grok API request failed: {e}")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Grok response as JSON: {e}")
            raise

    def _process_verification_result(self, grok_response, order):
        """
        Process and validate Grok's verification result.

        Args:
            grok_response (dict): Response from Grok API
            order (Order): Order being verified

        Returns:
            dict: Processed verification result
        """
        # Extract data
        extracted_data = {
            'amount': grok_response.get('amount'),
            'receiver_phone': grok_response.get('receiver_phone'),
            'sender_phone': grok_response.get('sender_phone'),
            'transaction_id': grok_response.get('transaction_id'),
            'transaction_date': grok_response.get('transaction_date'),
            'bank': grok_response.get('bank'),
        }

        verified = grok_response.get('verified', False)
        confidence = grok_response.get('confidence', 0)
        issues = grok_response.get('issues', [])

        # Additional validation
        additional_issues = self._validate_extracted_data(extracted_data, order)
        issues.extend(additional_issues)

        # Adjust verification based on additional validation
        if additional_issues:
            verified = False
            confidence = min(confidence, 60)  # Reduce confidence if issues found

        return {
            'verified': verified,
            'confidence': confidence,
            'extracted_data': extracted_data,
            'issues': issues
        }

    def _validate_extracted_data(self, data, order):
        """
        Perform additional validation on extracted data.

        Args:
            data (dict): Extracted data from Grok
            order (Order): Order being verified

        Returns:
            list: List of validation issues
        """
        issues = []

        # Validate amount
        try:
            extracted_amount = Decimal(str(data['amount']))
            expected_amount = order.total

            if abs(extracted_amount - expected_amount) > Decimal('0.01'):
                issues.append(
                    f"Monto no coincide: esperado ₡{expected_amount}, "
                    f"encontrado ₡{extracted_amount}"
                )
        except (TypeError, ValueError, KeyError):
            issues.append("No se pudo extraer el monto del comprobante")

        # Validate receiver phone
        expected_receiver = order.seller.seller_profile.sinpe_number
        extracted_receiver = data.get('receiver_phone', '')

        # Normalize phone numbers for comparison
        normalized_expected = self._normalize_phone(expected_receiver)
        normalized_extracted = self._normalize_phone(extracted_receiver)

        if normalized_expected != normalized_extracted:
            issues.append(
                f"Número de receptor no coincide: esperado {expected_receiver}, "
                f"encontrado {extracted_receiver}"
            )

        # Validate transaction date (within last hour)
        try:
            transaction_date_str = data.get('transaction_date')
            if transaction_date_str:
                transaction_date = datetime.fromisoformat(transaction_date_str.replace('Z', '+00:00'))
                max_age = timedelta(hours=1)

                if timezone.now() - transaction_date > max_age:
                    issues.append(
                        f"Transacción muy antigua: {transaction_date}. "
                        "Debe ser menor a 1 hora."
                    )
        except (ValueError, TypeError):
            issues.append("Fecha de transacción inválida o no encontrada")

        return issues

    @staticmethod
    def _normalize_phone(phone):
        """
        Normalize phone number for comparison.
        Removes spaces, dashes, and ensures +506 prefix.
        """
        if not phone:
            return ''

        # Remove spaces, dashes, parentheses
        normalized = ''.join(c for c in phone if c.isdigit() or c == '+')

        # Add +506 if not present
        if not normalized.startswith('+'):
            normalized = f'+506{normalized}'

        return normalized


class PaymentNotificationService:
    """
    Service to send notifications about payment status.
    """

    def notify_seller_new_payment(self, order):
        """Notify seller about new payment receipt to review."""
        # TODO: Implement with Twilio
        pass

    def notify_buyer_payment_approved(self, order):
        """Notify buyer that payment was approved."""
        # TODO: Implement with Twilio
        pass

    def notify_buyer_payment_rejected(self, order):
        """Notify buyer that payment was rejected."""
        # TODO: Implement with Twilio
        pass
