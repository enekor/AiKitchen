import 'package:aikitchen/models/recipe.dart';
import 'package:aikitchen/services/recipe_from_file_service.dart';
import 'package:flutter/material.dart';

class PreviewSharedFiles extends StatefulWidget {
  PreviewSharedFiles({Key? key, required this.recipeUri}) : super(key: key);

  final String recipeUri;
  late Recipe receta;
  @override
  _PreviewSharedFilesState createState() => _PreviewSharedFilesState();
}

class _PreviewSharedFilesState extends State<PreviewSharedFiles> {
  @override
  void initState() async {
    widget.receta = await RecipeFromFileService().loadRecipe(widget.recipeUri);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return // Suggested code may be subject to a license. Learn more: ~LicenseLog:1252231295.
    // Suggested code may be subject to a license. Learn more: ~LicenseLog:2711979707.
    // Suggested code may be subject to a license. Learn more: ~LicenseLog:4095339582.
    // Suggested code may be subject to a license. Learn more: ~LicenseLog:593838829.
    // Suggested code may be subject to a license. Learn more: ~LicenseLog:15262127.
    // Suggested code may be subject to a license. Learn more: ~LicenseLog:3568740846.
    // Suggested code may be subject to a license. Learn more: ~LicenseLog:3680493086.
    Scaffold(
      appBar: AppBar(title: const Text('Recipe Preview')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildSectionTitle('Recipe Name'),
              _buildDetailCard(widget.receta.nombre),
              _buildSectionTitle('Description'),
              _buildDetailCard(widget.receta.descripcion),
              _buildSectionTitle('Ingredients'),
              _buildDetailCard(widget.receta.ingredientes.join(', ')),
              _buildSectionTitle('Instructions'),
              _buildDetailCard(widget.receta.preparacion.join('\n')),
              _buildSectionTitle('Total Time'),
              _buildDetailCard(widget.receta.tiempoEstimado),
              _buildSectionTitle('Calorias'),
              _buildDetailCard('${widget.receta.calorias} cal'),
              _buildSectionTitle('Servings'),
              _buildDetailCard('${widget.receta.raciones} reciones'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailCard(String detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            offset: const Offset(4, 4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        detail,
        style: TextStyle(fontSize: 16, color: Colors.grey.shade900),
      ),
    );
  }
}
