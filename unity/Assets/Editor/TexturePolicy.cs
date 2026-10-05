using UnityEditor;
namespace GhostRally.Editor {
 public sealed class TexturePolicy:AssetPostprocessor {
  void OnPreprocessTexture(){if(!assetPath.StartsWith("Assets/Resources/Migration/"))return;var importer=(TextureImporter)assetImporter;importer.mipmapEnabled=true;importer.anisoLevel=4;importer.maxTextureSize=1024;importer.isReadable=false;bool normal=assetPath.Contains("_nor_")||assetPath.Contains("_normal");if(normal)importer.textureType=TextureImporterType.NormalMap;var android=new TextureImporterPlatformSettings{name="Android",overridden=true,maxTextureSize=1024,format=TextureImporterFormat.ASTC_6x6};importer.SetPlatformTextureSettings(android);}
 }
}
