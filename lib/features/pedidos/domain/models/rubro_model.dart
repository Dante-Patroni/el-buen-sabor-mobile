class Rubro {
  final int id;
  final String denominacion;
  final List<Rubro> subrubros;

  /**
   * @description Crea una instancia de Rubro.
   * @param {int} id - Identificador del rubro.
   * @param {String} denominacion - Nombre del rubro.
   * @param {List<Rubro>} subrubros - Subrubros del rubro.
   * @returns {Rubro} Instancia creada.
   * @throws {Error} No lanza errores por diseno.
   */
  Rubro({
    required this.id,
    required this.denominacion,
    this.subrubros = const [],
  });

  /**
   * @description Construye un Rubro desde JSON.
   * @param {Map<String, dynamic>} json - Datos del rubro.
   * @returns {Rubro} Rubro parseado.
   * @throws {Error} No lanza errores por diseno.
   */
  factory Rubro.fromJson(Map<String, dynamic> json) {
    var list = json['subrubros'] as List?;
    List<Rubro> subs =
        list != null ? list.map((i) => Rubro.fromJson(i)).toList() : [];

    return Rubro(
      id: json['id'],
      denominacion: json['denominacion'],
      subrubros: subs,
    );
  }
}
