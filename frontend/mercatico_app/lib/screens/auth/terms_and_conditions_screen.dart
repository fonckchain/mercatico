import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y Condiciones de Uso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Última actualización: ${DateTime.now().year}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // AQUÍ PEGA TUS TÉRMINOS Y CONDICIONES
            // Puedes usar const Text() para cada párrafo o sección
            // Ejemplo:
            const Text(
              'Bienvenido(a) a MercaTico, una plataforma digital diseñada para conectar emprendedores costarricenses con compradores, facilitando la venta de productos y servicios sin comisiones, utilizando métodos de pago como SINPE Móvil o efectivo. Al acceder o utilizar nuestra aplicación móvil y/o sitio web (en adelante, "la Plataforma"), usted acepta cumplir con los siguientes Términos y Condiciones (en adelante, "Términos"). Si no está de acuerdo con estos Términos, por favor no utilice la Plataforma.
              
              1. Aceptación de los Términos
              1.1. Estos Términos constituyen un contrato legalmente vinculante entre usted (el "Usuario", ya sea "Comprador" o "Vendedor") y MercaTico (en adelante, "nosotros" o "la Plataforma").
1.2. Nos reservamos el derecho de modificar estos Términos en cualquier momento. Las modificaciones serán efectivas una vez publicadas en la Plataforma, y el uso continuado de la misma implica la aceptación de dichas modificaciones.
1.3. Es responsabilidad del Usuario revisar periódicamente los Términos para estar al tanto de cualquier cambio.

2. Descripción del Servicio
2.1. MercaTico es un marketplace que permite a emprendedores costarricenses (Vendedores) ofrecer productos y servicios a compradores, sin que la Plataforma cobre comisiones por las transacciones realizadas.
2.2. Las transacciones se realizan directamente entre el Comprador y el Vendedor, utilizando SINPE Móvil o efectivo como métodos de pago. MercaTico no interviene en el procesamiento de pagos ni actúa como intermediario financiero.
2.3. MercaTico proporciona una plataforma para la publicación de productos y servicios, pero no es responsable de la calidad, seguridad, legalidad o entrega de los mismos, ni de las transacciones realizadas fuera de la Plataforma.

3. Elegibilidad
3.1. Para utilizar MercaTico, el Usuario debe:Ser mayor de 18 años o contar con autorización de un tutor legal.
Residir en Costa Rica o ser ciudadano costarricense.
Proporcionar información veraz y completa durante el registro.
3.2. Los Vendedores deben ser emprendedores costarricenses que cumplan con las leyes locales aplicables, incluyendo, pero no limitándose a, regulaciones fiscales y de comercio.

4. Registro y Cuenta de Usuario
4.1. Para utilizar ciertas funcionalidades de la Plataforma, los Usuarios deben crear una cuenta proporcionando información precisa, como nombre, correo electrónico, número de teléfono y, en el caso de Vendedores, información adicional para verificar su identidad y negocio.
4.2. El Usuario es responsable de mantener la confidencialidad de las credenciales de su cuenta y de todas las actividades realizadas bajo la misma.
4.3. MercaTico se reserva el derecho de suspender o eliminar cuentas que violen estos Términos, incluyan información falsa o participen en actividades fraudulentas.

5. Uso de la Plataforma
5.1. Obligaciones de los Vendedores:Publicar descripciones precisas, completas y no engañosas de los productos o servicios ofrecidos.
Cumplir con todas las leyes y regulaciones aplicables en Costa Rica, incluyendo la obtención de permisos o licencias necesarias.
Gestionar directamente con los Compradores los pagos (vía SINPE Móvil o efectivo) y la entrega de los productos o servicios.
Responder a las consultas de los Compradores de manera oportuna.
5.2. Obligaciones de los Compradores:
Realizar pagos únicamente a través de los métodos acordados con el Vendedor (SINPE Móvil o efectivo).
Proporcionar información veraz para coordinar la entrega de productos o servicios.
5.3. Prohibiciones:
Publicar contenido ilegal, ofensivo, fraudulento o que infrinja derechos de terceros (propiedad intelectual, privacidad, etc.).
Utilizar la Plataforma para fines distintos a los establecidos en estos Términos.
Realizar transacciones fuera de los métodos de pago permitidos por la Plataforma (SINPE Móvil o efectivo).

6. Transacciones y Pagos
6.1. MercaTico no procesa pagos ni actúa como intermediario en las transacciones entre Compradores y Vendedores.
6.2. Los pagos se realizarán directamente entre el Comprador y el Vendedor mediante SINPE Móvil o efectivo, según lo acordado por ambas partes.
6.3. MercaTico no se hace responsable por disputas, retrasos, fraudes o problemas relacionados con los pagos o la entrega de productos/servicios.
6.4. Los Vendedores son responsables de emitir comprobantes electrónicos o cualquier documentación fiscal requerida por la legislación costarricense.

7. Política de Contenido
7.1. Los Vendedores son responsables de garantizar que el contenido publicado (imágenes, descripciones, precios, etc.) sea preciso, legal y no infrinja derechos de terceros.
7.2. MercaTico se reserva el derecho de eliminar cualquier contenido que considere inapropiado, ilegal o que viole estos Términos, sin notificación previa.

8. Propiedad Intelectual
8.1 8.1. MercaTico opera bajo un modelo open-source. Todo el código fuente de la Plataforma, incluyendo el software, las interfaces y las funcionalidades técnicas, está licenciado bajo MIT, lo que permite a los usuarios acceder, modificar y distribuir el código conforme a los términos de dicha licencia. El código fuente está disponible en https://github.com/fonckchain/mercatico.
8.2. Los Usuarios conservan los derechos sobre el contenido que publican, pero otorgan a MercaTico una licencia no exclusiva, mundial y libre de regalías para usar, reproducir y mostrar dicho contenido en la Plataforma con fines promocionales o operativos.

9. Protección de Datos Personales
9.1. MercaTico recopila, almacena y procesa datos personales de los Usuarios de acuerdo con la Ley de Protección de la Persona frente al Tratamiento de sus Datos Personales (Ley N° 8968) de Costa Rica.
9.2. Los datos proporcionados por los Usuarios serán utilizados únicamente para operar la Plataforma, facilitar transacciones y cumplir con las leyes aplicables.
9.3. Para más información, consulte nuestra Política de Privacidad [enlazar a la política de privacidad, si existe].

10. Limitación de Responsabilidad
10.1. MercaTico no garantiza la disponibilidad ininterrumpida de la Plataforma ni la exactitud de la información proporcionada por los Usuarios.
10.2. MercaTico no se responsabiliza por:Disputas entre Compradores y Vendedores, incluyendo problemas con productos, servicios, pagos o entregas.
Pérdidas, daños o perjuicios derivados del uso de la Plataforma.
Acciones fraudulentas o ilegales de los Usuarios.
10.3. La Plataforma se proporciona "tal cual", sin garantías implícitas o explícitas.

11. Resolución de Disputas
11.1. Cualquier disputa entre Usuarios debe resolverse directamente entre las partes involucradas. MercaTico puede, a su discreción, actuar como mediador, pero no está obligado a hacerlo.
11.2. En caso de disputas legales entre un Usuario y MercaTico, estas se resolverán en los tribunales de San José, Costa Rica, bajo las leyes costarricenses.

12. Terminación
12.1. MercaTico puede suspender o cancelar el acceso de un Usuario a la Plataforma en caso de incumplimiento de estos Términos, sin previo aviso.
12.2. Los Usuarios pueden cerrar su cuenta en cualquier momento notificando a MercaTico a través de los canales oficiales.

13. ContactoPara consultas, quejas o soporte, contáctenos en:Correo electrónico: ops@fast-blocks.xyz
Teléfono: +506 7158-6206

14. Disposiciones Generales
14.1. Estos Términos se rigen por las leyes de la República de Costa Rica.
14.2. Si alguna disposición de estos Términos es declarada inválida, las demás disposiciones permanecerán en vigor.
14.3. La falta de ejercicio de cualquier derecho por parte de MercaTico no implica una renuncia a dicho derecho.

',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 32),

            // Botón para cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Entendido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
