class Rubro {
  final int id;
  final String denominacion;
  final List<Rubro> subrubros;

  Rubro({
    required this.id,
    required this.denominacion,
    this.subrubros = const [],
  });

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
