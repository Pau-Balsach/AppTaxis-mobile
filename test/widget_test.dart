import 'package:flutter_test/flutter_test.dart';
import 'package:apptaxis/models/cliente.dart';
import 'package:apptaxis/models/conductor.dart';
import 'package:apptaxis/models/viaje.dart';
import 'package:apptaxis/services/app_exception.dart';

// ═══════════════════════════════════════════════════════════════
// HELPERS / FIXTURES
// ═══════════════════════════════════════════════════════════════

Map<String, dynamic> _conductorJson({
  int id = 1,
  String matricula = '1234ABC',
  String nombre = 'Juan López',
  String? condAdmin,
}) =>
    {
      'id': id,
      'matricula': matricula,
      'nombre': nombre,
      if (condAdmin != null) 'cond_admin': condAdmin,
    };

Map<String, dynamic> _clienteJson({
  int id = 5,
  String nombre = 'Ana García',
  String telefono = '612345678',
  String? email,
  String? notas,
  String? adminId,
}) =>
    {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      if (email != null) 'email': email,
      if (notas != null) 'notas': notas,
      if (adminId != null) 'adminId': adminId,
    };

Map<String, dynamic> _viajeJson({
  String id = 'viaje-001',
  String dia = '2025-06-15',
  String? diaFin,
  String hora = '22:30:00',
  String horaFinalizacion = '01:00:00',
  String puntorecogida = 'Aeropuerto',
  String puntodejada = 'Hotel Centro',
  String telefonocliente = '600111222',
  Map<String, dynamic>? conductor,
  Map<String, dynamic>? cliente,
}) =>
    {
      'id': id,
      'dia': dia,
      if (diaFin != null) 'diaFin': diaFin,
      'hora': hora,
      'horaFinalizacion': horaFinalizacion,
      'puntorecogida': puntorecogida,
      'puntodejada': puntodejada,
      'telefonocliente': telefonocliente,
      if (conductor != null) 'conductor': conductor,
      if (cliente != null) 'cliente': cliente,
    };

void main() {
  // ═══════════════════════════════════════════════════════════════
  // CLIENTE
  // ═══════════════════════════════════════════════════════════════
  group('Cliente', () {
    // ── fromJson ──────────────────────────────────────────────
    group('fromJson', () {
      test('todos los campos', () {
        final c = Cliente.fromJson(_clienteJson(
          id: 1,
          nombre: 'Ana García',
          telefono: '612345678',
          email: 'ana@example.com',
          notas: 'Cliente VIP',
          adminId: 'admin-001',
        ));

        expect(c.id, 1);
        expect(c.nombre, 'Ana García');
        expect(c.telefono, '612345678');
        expect(c.email, 'ana@example.com');
        expect(c.notas, 'Cliente VIP');
        expect(c.adminId, 'admin-001');
      });

      test('campos opcionales ausentes quedan null', () {
        final c = Cliente.fromJson({'id': 2, 'nombre': 'Pedro', 'telefono': '600111222'});
        expect(c.email, isNull);
        expect(c.notas, isNull);
        expect(c.adminId, isNull);
      });

      test('acepta adminId como alias de admin_id', () {
        final c = Cliente.fromJson({
          'id': 3,
          'nombre': 'Luis',
          'telefono': '699000111',
          'adminId': 'admin-xyz',
        });
        expect(c.adminId, 'admin-xyz');
      });

      test('acepta admin_id (snake_case) como alias', () {
        final c = Cliente.fromJson({
          'id': 3,
          'nombre': 'Luis',
          'telefono': '699000111',
          'admin_id': 'admin-snake',
        });
        expect(c.adminId, 'admin-snake');
      });

      test('adminId tiene prioridad sobre admin_id cuando ambos presentes', () {
        final c = Cliente.fromJson({
          'id': 3,
          'nombre': 'Luis',
          'telefono': '699000111',
          'adminId': 'camelCase',
          'admin_id': 'snakeCase',
        });
        // adminId se lee primero en el factory
        expect(c.adminId, 'camelCase');
      });
    });

    // ── toJson ────────────────────────────────────────────────
    group('toJson', () {
      test('omite campos nulos', () {
        final c = Cliente(id: 4, nombre: 'María', telefono: '611222333');
        final json = c.toJson();
        expect(json.containsKey('email'), isFalse);
        expect(json.containsKey('notas'), isFalse);
        expect(json.containsKey('adminId'), isFalse);
      });

      test('incluye campos opcionales cuando están presentes', () {
        final c = Cliente(
          id: 5,
          nombre: 'Carlos',
          telefono: '611999888',
          email: 'carlos@test.com',
          notas: 'Notas de prueba',
        );
        final json = c.toJson();
        expect(json['email'], 'carlos@test.com');
        expect(json['notas'], 'Notas de prueba');
      });

      test('siempre incluye id, nombre y telefono', () {
        final c = Cliente(id: 99, nombre: 'Test', telefono: '600000000');
        final json = c.toJson();
        expect(json['id'], 99);
        expect(json['nombre'], 'Test');
        expect(json['telefono'], '600000000');
      });

      test('round-trip fromJson → toJson conserva los datos', () {
        final original = _clienteJson(
          email: 'roundtrip@test.com',
          notas: 'nota',
          adminId: 'adm-1',
        );
        final c = Cliente.fromJson(original);
        final json = c.toJson();
        expect(json['id'], original['id']);
        expect(json['nombre'], original['nombre']);
        expect(json['telefono'], original['telefono']);
        expect(json['email'], original['email']);
        expect(json['notas'], original['notas']);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // CONDUCTOR
  // ═══════════════════════════════════════════════════════════════
  group('Conductor', () {
    // ── fromJson ──────────────────────────────────────────────
    group('fromJson', () {
      test('todos los campos con cond_admin (snake)', () {
        final c = Conductor.fromJson(_conductorJson(condAdmin: 'cond-admin-1'));
        expect(c.id, 1);
        expect(c.matricula, '1234ABC');
        expect(c.nombre, 'Juan López');
        expect(c.condAdmin, 'cond-admin-1');
      });

      test('acepta condAdmin (camelCase) como alias', () {
        final json = {'id': 11, 'matricula': '5678DEF', 'nombre': 'Rosa', 'condAdmin': 'cond-admin-2'};
        final c = Conductor.fromJson(json);
        expect(c.condAdmin, 'cond-admin-2');
      });

      test('sin condAdmin deja el campo nulo', () {
        final c = Conductor.fromJson({'id': 12, 'matricula': '9999ZZZ', 'nombre': 'Sin Admin'});
        expect(c.condAdmin, isNull);
      });
    });

    // ── toJson ────────────────────────────────────────────────
    group('toJson', () {
      test('omite cond_admin cuando es nulo', () {
        final c = Conductor(id: 13, matricula: '1111AAA', nombre: 'Test');
        expect(c.toJson().containsKey('cond_admin'), isFalse);
      });

      test('incluye cond_admin cuando no es nulo', () {
        final c = Conductor(id: 14, matricula: '2222BBB', nombre: 'Con Admin', condAdmin: 'adm');
        expect(c.toJson()['cond_admin'], 'adm');
      });

      test('siempre incluye id, matricula y nombre', () {
        final c = Conductor(id: 15, matricula: '3333CCC', nombre: 'Check');
        final json = c.toJson();
        expect(json['id'], 15);
        expect(json['matricula'], '3333CCC');
        expect(json['nombre'], 'Check');
      });
    });

    // ── igualdad y hashCode ───────────────────────────────────
    group('igualdad y hashCode', () {
      test('igual si mismo id, diferente matricula/nombre', () {
        final c1 = Conductor(id: 1, matricula: '1234ABC', nombre: 'A');
        final c2 = Conductor(id: 1, matricula: 'DISTINTA', nombre: 'B');
        expect(c1, equals(c2));
      });

      test('distinto si diferente id', () {
        final c1 = Conductor(id: 1, matricula: '1234ABC', nombre: 'A');
        final c3 = Conductor(id: 2, matricula: '1234ABC', nombre: 'A');
        expect(c1, isNot(equals(c3)));
      });

      test('hashCode consistente con igualdad', () {
        final c1 = Conductor(id: 99, matricula: 'X', nombre: 'X');
        final c2 = Conductor(id: 99, matricula: 'Y', nombre: 'Y');
        expect(c1.hashCode, equals(c2.hashCode));
      });

      test('objetos diferentes id tienen hashCode diferente (probabilístico)', () {
        final c1 = Conductor(id: 1, matricula: 'X', nombre: 'X');
        final c2 = Conductor(id: 2, matricula: 'X', nombre: 'X');
        expect(c1.hashCode, isNot(equals(c2.hashCode)));
      });

      test('un Conductor no es igual a otro tipo', () {
        final c = Conductor(id: 1, matricula: 'X', nombre: 'X');
        expect(c == 'string', isFalse);
        expect(c == 1, isFalse);
      });

      test('un Conductor es igual a sí mismo (identical)', () {
        final c = Conductor(id: 1, matricula: 'X', nombre: 'X');
        // ignore: unrelated_type_equality_checks
        expect(c == c, isTrue);
      });

      test('puede usarse como clave de Map gracias al hashCode', () {
        final map = <Conductor, String>{};
        final c1 = Conductor(id: 5, matricula: 'A', nombre: 'A');
        final c2 = Conductor(id: 5, matricula: 'B', nombre: 'B'); // mismo id
        map[c1] = 'valor';
        expect(map[c2], 'valor');
      });

      test('puede usarse en Set sin duplicados', () {
        final c1 = Conductor(id: 3, matricula: 'A', nombre: 'A');
        final c2 = Conductor(id: 3, matricula: 'B', nombre: 'B');
        final c3 = Conductor(id: 4, matricula: 'C', nombre: 'C');
        final set = {c1, c2, c3};
        expect(set.length, 2);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // VIAJE
  // ═══════════════════════════════════════════════════════════════
  group('Viaje', () {
    // ── fromJson ──────────────────────────────────────────────
    group('fromJson', () {
      test('parsea viaje completo correctamente', () {
        final v = Viaje.fromJson(_viajeJson(
          diaFin: '2025-06-16',
          conductor: _conductorJson(),
          cliente: _clienteJson(),
        ));

        expect(v.id, 'viaje-001');
        expect(v.dia, '2025-06-15');
        expect(v.diaFin, '2025-06-16');
        expect(v.hora, '22:30');
        expect(v.horaFinalizacion, '01:00');
        expect(v.puntorecogida, 'Aeropuerto');
        expect(v.puntodejada, 'Hotel Centro');
        expect(v.conductor, isNotNull);
        expect(v.cliente, isNotNull);
      });

      test('sin conductor ni cliente deja campos nulos', () {
        final v = Viaje.fromJson(_viajeJson());
        expect(v.conductor, isNull);
        expect(v.cliente, isNull);
      });

      test('hora recortada a HH:mm (5 chars)', () {
        final v = Viaje.fromJson(_viajeJson(hora: '08:45:30', horaFinalizacion: '09:15:00'));
        expect(v.hora.length, 5);
        expect(v.hora, '08:45');
        expect(v.horaFinalizacion, '09:15');
      });

      test('hora más corta de 5 chars se devuelve tal cual (sin crash)', () {
        final v = Viaje.fromJson(_viajeJson(hora: '8:00', horaFinalizacion: ''));
        expect(v.hora, '8:00');
      });

      test('hora vacía se mapea a cadena vacía', () {
        final json = _viajeJson(hora: '', horaFinalizacion: '');
        // hora vacía: recortar devuelve ''
        final v = Viaje.fromJson(json);
        expect(v.hora, '');
      });

      test('conductor anidado se parsea correctamente', () {
        final v = Viaje.fromJson(_viajeJson(
          conductor: _conductorJson(condAdmin: 'admin-x'),
        ));
        expect(v.conductor!.matricula, '1234ABC');
        expect(v.conductor!.condAdmin, 'admin-x');
      });

      test('cliente anidado se parsea correctamente', () {
        final v = Viaje.fromJson(_viajeJson(
          cliente: _clienteJson(email: 'test@x.com', notas: 'vip'),
        ));
        expect(v.cliente!.nombre, 'Ana García');
        expect(v.cliente!.email, 'test@x.com');
        expect(v.cliente!.notas, 'vip');
      });
    });

    // ── cruzaMedianoche ───────────────────────────────────────
    group('cruzaMedianoche', () {
      test('true cuando diaFin != dia', () {
        final v = Viaje.fromJson(_viajeJson(dia: '2025-09-01', diaFin: '2025-09-02'));
        expect(v.cruzaMedianoche, isTrue);
      });

      test('false cuando diaFin == dia', () {
        final v = Viaje.fromJson(_viajeJson(dia: '2025-09-01', diaFin: '2025-09-01'));
        expect(v.cruzaMedianoche, isFalse);
      });

      test('false cuando diaFin es nulo', () {
        final v = Viaje.fromJson(_viajeJson(dia: '2025-09-01'));
        expect(v.cruzaMedianoche, isFalse);
      });

      test('false con Viaje construido directamente sin diaFin', () {
        final v = Viaje(
          id: 'x',
          dia: '2025-09-01',
          hora: '22:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
        expect(v.cruzaMedianoche, isFalse);
      });
    });

    // ── diaDateTime / diaFinDateTime ──────────────────────────
    group('conversión DateTime', () {
      test('diaDateTime y diaFinDateTime convierten correctamente', () {
        final v = Viaje.fromJson(_viajeJson(dia: '2025-10-05', diaFin: '2025-10-06'));
        expect(v.diaDateTime, DateTime.parse('2025-10-05'));
        expect(v.diaFinDateTime, DateTime.parse('2025-10-06'));
      });

      test('diaFinDateTime usa diaFin=null → dia como fallback', () {
        final v = Viaje.fromJson(_viajeJson(dia: '2025-10-05'));
        // diaFin es null, fallback a dia
        expect(v.diaFinDateTime, DateTime.parse('2025-10-05'));
      });

      test('diaDateTime es anterior a diaFinDateTime en viaje de medianoche', () {
        final v = Viaje.fromJson(_viajeJson(dia: '2025-10-05', diaFin: '2025-10-06'));
        expect(v.diaDateTime.isBefore(v.diaFinDateTime), isTrue);
      });
    });

    // ── toJson ────────────────────────────────────────────────
    group('toJson', () {
      test('no incluye horaFinalizacion si está vacía', () {
        final v = Viaje(
          id: 'v-008',
          dia: '2025-11-01',
          hora: '10:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
        expect(v.toJson().containsKey('horaFinalizacion'), isFalse);
      });

      test('incluye horaFinalizacion cuando no está vacía', () {
        final v = Viaje(
          id: 'v-fin',
          dia: '2025-11-01',
          hora: '10:00',
          horaFinalizacion: '11:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
        expect(v.toJson()['horaFinalizacion'], '11:00');
      });

      test('diaFin cae back a dia si es nulo en toJson', () {
        final v = Viaje(
          id: 'v-dF',
          dia: '2025-11-01',
          hora: '10:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
        expect(v.toJson()['diaFin'], '2025-11-01');
      });

      test('toJson no incluye conductor ni cliente (son campos de red, no del payload base)', () {
        final v = Viaje.fromJson(_viajeJson(conductor: _conductorJson(), cliente: _clienteJson()));
        final json = v.toJson();
        expect(json.containsKey('conductor'), isFalse);
        expect(json.containsKey('cliente'), isFalse);
      });
    });

    // ── toJsonConCliente ──────────────────────────────────────
    group('toJsonConCliente', () {
      late Viaje v;
      setUp(() {
        v = Viaje(
          id: 'v-clt',
          dia: '2025-11-01',
          hora: '10:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
      });

      test('incluye cliente cuando clienteId no es nulo', () {
        final json = v.toJsonConCliente(42);
        expect(json['cliente'], {'id': 42});
      });

      test('no incluye clave cliente cuando clienteId es nulo', () {
        final json = v.toJsonConCliente(null);
        expect(json.containsKey('cliente'), isFalse);
      });

      test('contiene los campos base del viaje', () {
        final json = v.toJsonConCliente(1);
        expect(json['dia'], '2025-11-01');
        expect(json['hora'], '10:00');
        expect(json['puntorecogida'], 'A');
        expect(json['puntodejada'], 'B');
        expect(json['telefonocliente'], '600000000');
      });

      test('clienteId 0 sigue siendo incluido (no es null)', () {
        final json = v.toJsonConCliente(0);
        expect(json['cliente'], {'id': 0});
      });
    });

    // ── constructor directo ───────────────────────────────────
    group('constructor', () {
      test('horaFinalizacion por defecto es cadena vacía', () {
        final v = Viaje(
          id: 'x',
          dia: '2025-01-01',
          hora: '09:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
        expect(v.horaFinalizacion, '');
      });

      test('diaFin por defecto es nulo', () {
        final v = Viaje(
          id: 'x',
          dia: '2025-01-01',
          hora: '09:00',
          puntorecogida: 'A',
          puntodejada: 'B',
          telefonocliente: '600000000',
        );
        expect(v.diaFin, isNull);
      });
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // APP_EXCEPTION
  // ═══════════════════════════════════════════════════════════════
  group('AppException y subclases', () {
    test('AppException.toString devuelve el mensaje', () {
      const e = AppException('algo salió mal');
      expect(e.toString(), 'algo salió mal');
    });

    test('AppException guarda statusCode', () {
      const e = AppException('error', statusCode: 404);
      expect(e.statusCode, 404);
    });

    test('AppException sin statusCode lo deja nulo', () {
      const e = AppException('sin código');
      expect(e.statusCode, isNull);
    });

    test('NetworkException es AppException', () {
      const e = NetworkException('sin red');
      expect(e, isA<AppException>());
      expect(e.message, 'sin red');
    });

    test('RequestTimeoutException es AppException', () {
      const e = RequestTimeoutException('timeout');
      expect(e, isA<AppException>());
    });

    test('AuthException guarda statusCode', () {
      const e = AuthException('no autorizado', statusCode: 401);
      expect(e.statusCode, 401);
      expect(e, isA<AppException>());
    });

    test('ServerException guarda statusCode', () {
      const e = ServerException('error servidor', statusCode: 500);
      expect(e.statusCode, 500);
      expect(e, isA<AppException>());
    });

    test('puede capturarse como Exception genérico', () {
      void lanzar() => throw const AppException('boom');
      expect(lanzar, throwsA(isA<Exception>()));
    });

    test('puede capturarse como AppException específico', () {
      void lanzar() => throw const NetworkException('sin red');
      expect(lanzar, throwsA(isA<AppException>()));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // INTEGRACIÓN: Viaje + Conductor + Cliente juntos
  // ═══════════════════════════════════════════════════════════════
  group('Integración Viaje ↔ Conductor ↔ Cliente', () {
    test('viaje con conductor y cliente parsea relaciones anidadas completas', () {
      final json = _viajeJson(
        diaFin: '2025-12-26',
        conductor: _conductorJson(condAdmin: 'adm-1'),
        cliente: _clienteJson(email: 'cli@test.com', notas: 'VIP', adminId: 'adm-cli'),
      );
      final v = Viaje.fromJson(json);

      expect(v.conductor!.id, 1);
      expect(v.conductor!.condAdmin, 'adm-1');
      expect(v.cliente!.email, 'cli@test.com');
      expect(v.cliente!.adminId, 'adm-cli');
      expect(v.cruzaMedianoche, isTrue);
    });

    test('varios viajes con mismo conductor se pueden agrupar en Map', () {
      final conductor = Conductor.fromJson(_conductorJson(id: 7));
      final v1 = Viaje.fromJson(_viajeJson(id: 'a', conductor: _conductorJson(id: 7)));
      final v2 = Viaje.fromJson(_viajeJson(id: 'b', conductor: _conductorJson(id: 7)));
      final v3 = Viaje.fromJson(_viajeJson(id: 'c', conductor: _conductorJson(id: 99)));

      final porConductor = <Conductor, List<Viaje>>{};
      for (final v in [v1, v2, v3]) {
        if (v.conductor != null) {
          porConductor.putIfAbsent(v.conductor!, () => []).add(v);
        }
      }

      expect(porConductor[conductor]!.length, 2);
    });

    test('lista de viajes ordenable por hora', () {
      final viajes = [
        Viaje.fromJson(_viajeJson(id: 'c', hora: '22:00:00')),
        Viaje.fromJson(_viajeJson(id: 'a', hora: '08:00:00')),
        Viaje.fromJson(_viajeJson(id: 'b', hora: '14:30:00')),
      ];
      viajes.sort((a, b) => a.hora.compareTo(b.hora));
      expect(viajes.map((v) => v.id).toList(), ['a', 'b', 'c']);
    });

    test('filtrar viajes de un día concreto (lógica de _viajesParaDia)', () {
      const dia = '2025-09-01';
      final viajesMes = [
        Viaje.fromJson(_viajeJson(id: '1', dia: dia)),
        Viaje.fromJson(_viajeJson(id: '2', dia: '2025-09-02')),
        Viaje.fromJson(_viajeJson(id: '3', dia: dia, diaFin: '2025-09-02')),
      ];

      final filtrados = viajesMes.where((v) => v.dia == dia || v.cruzaMedianoche).toList();
      expect(filtrados.map((v) => v.id), containsAll(['1', '3']));
      expect(filtrados.map((v) => v.id), isNot(contains('2')));
    });

    test('toJsonConCliente con cliente ya en el viaje — id correcto', () {
      final v = Viaje.fromJson(_viajeJson(cliente: _clienteJson(id: 10)));
      // se sobreescribe con clienteId 99 externo
      final json = v.toJsonConCliente(99);
      expect(json['cliente'], {'id': 99});
    });
  });
}