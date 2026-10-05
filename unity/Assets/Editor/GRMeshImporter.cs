using System;
using System.IO;
using System.IO.Compression;
using UnityEditor;
using UnityEditor.AssetImporters;
using UnityEngine;
using UnityEngine.Rendering;
namespace GhostRally.Editor {
 [ScriptedImporter(1,"grmesh")]
 public sealed class GRMeshImporter : ScriptedImporter {
  [Serializable] public class MaterialData { public string name,texture;public float[] color,emission;public float metallic,roughness,cutoff;public bool cutout,doubleSided,worldAtlas;public int atlasKind; }
  [Serializable] public class Primitive {public int offset,vertices,indices,material,stride;}
  [Serializable] public class MeshData {public Primitive[] primitives;}
  [Serializable] public class NodeData {public string name;public int mesh;public int[] children;public float[] position,rotation,scale,matrix;}
  [Serializable] public class Document {public MaterialData[] materials;public MeshData[] meshes;public NodeData[] nodes;public int[] roots;}
  public override void OnImportAsset(AssetImportContext ctx) {
   byte[] bytes=File.ReadAllBytes(ctx.assetPath);
   if(bytes.Length>2&&bytes[0]==0x1f&&bytes[1]==0x8b){using(var source=new MemoryStream(bytes))using(var zip=new GZipStream(source,CompressionMode.Decompress))using(var target=new MemoryStream()){zip.CopyTo(target);bytes=target.ToArray();}}
   using(var reader=new BinaryReader(new MemoryStream(bytes))) {
    if(new string(reader.ReadChars(4))!="GRM1")throw new InvalidDataException("Wrong GRMesh signature");
    int length=reader.ReadInt32();var d=JsonUtility.FromJson<Document>(System.Text.Encoding.UTF8.GetString(reader.ReadBytes(length)));long start=reader.BaseStream.Position;
    var materials=new Material[d.materials.Length];
    for(int i=0;i<materials.Length;i++) {
     var s=d.materials[i];if(s.worldAtlas)ctx.DependsOnSourceAsset("Assets/Shaders/WorldAtlas.shader");var shader=s.worldAtlas?AssetDatabase.LoadAssetAtPath<Shader>("Assets/Shaders/WorldAtlas.shader"):Shader.Find("Universal Render Pipeline/Lit");var m=new Material(shader){name=s.name,enableInstancing=true};
     m.SetColor("_BaseColor",new Color(s.color[0],s.color[1],s.color[2],s.color[3]));m.SetFloat("_Metallic",s.metallic);m.SetFloat("_Smoothness",1-s.roughness);
     m.SetFloat("_Cull",s.doubleSided?0:2);if(s.worldAtlas){m.SetFloat("_Kind",s.atlasKind);foreach(var pair in new[]{new[]{"_Brick","Bricks001"},new[]{"_Plaster","Plaster002"}}){string folder="Assets/Resources/Migration/SourceTextures/textures/facades27/"+pair[1]+"_1K-JPG_";foreach(var map in new[]{new[]{"Map","Color"},new[]{"Normal","NormalGL"},new[]{"Rough","Roughness"}}){string source=folder+map[1]+".jpg";ctx.DependsOnSourceAsset(source);m.SetTexture(pair[0]+map[0],AssetDatabase.LoadAssetAtPath<Texture2D>(source));}}}
     if(!string.IsNullOrEmpty(s.texture)){ctx.DependsOnSourceAsset(s.texture);m.SetTexture("_BaseMap",AssetDatabase.LoadAssetAtPath<Texture2D>(s.texture));}
     if(s.cutout){m.SetFloat("_AlphaClip",1);m.SetFloat("_Cutoff",s.cutoff);m.EnableKeyword("_ALPHATEST_ON");m.renderQueue=2450;}
     if(s.emission!=null&&s.emission.Length==3){m.SetColor("_EmissionColor",new Color(s.emission[0],s.emission[1],s.emission[2]));m.EnableKeyword("_EMISSION");}
     ctx.AddObjectToAsset("material"+i,m);materials[i]=m;
    }
    var meshes=new Mesh[d.meshes.Length][];var meshMaterials=new Material[d.meshes.Length][];
    for(int mi=0;mi<meshes.Length;mi++) {
     var ps=d.meshes[mi].primitives;meshes[mi]=new Mesh[ps.Length];meshMaterials[mi]=new Material[ps.Length];
     for(int pi=0;pi<ps.Length;pi++) {
      var p=ps[pi];reader.BaseStream.Position=start+p.offset;var v=new Vector3[p.vertices];var n=new Vector3[p.vertices];var uv=new Vector2[p.vertices];var colors=new Color[p.vertices];
      for(int k=0;k<p.vertices;k++){v[k]=new Vector3(reader.ReadSingle(),reader.ReadSingle(),reader.ReadSingle());n[k]=new Vector3(reader.ReadSingle(),reader.ReadSingle(),reader.ReadSingle());uv[k]=new Vector2(reader.ReadSingle(),reader.ReadSingle());colors[k]=p.stride==48?new Color(reader.ReadSingle(),reader.ReadSingle(),reader.ReadSingle(),reader.ReadSingle()):Color.white;}
      var ids=new int[p.indices];for(int k=0;k<ids.Length;k++)ids[k]=reader.ReadInt32();
      var mesh=new Mesh{name="mesh"+mi+"_"+pi,indexFormat=IndexFormat.UInt32};mesh.vertices=v;mesh.normals=n;mesh.uv=uv;mesh.colors=colors;mesh.triangles=ids;mesh.RecalculateBounds();mesh.RecalculateTangents();
      ctx.AddObjectToAsset(mesh.name,mesh);meshes[mi][pi]=mesh;meshMaterials[mi][pi]=p.material>=0?materials[p.material]:new Material(Shader.Find("Universal Render Pipeline/Lit"));
     }
    }
    var root=new GameObject(Path.GetFileNameWithoutExtension(ctx.assetPath));var nodes=new GameObject[d.nodes.Length];
    for(int i=0;i<nodes.Length;i++)nodes[i]=new GameObject(d.nodes[i].name);
    for(int i=0;i<nodes.Length;i++)foreach(int child in d.nodes[i].children)nodes[child].transform.SetParent(nodes[i].transform,false);
    foreach(int i in d.roots)nodes[i].transform.SetParent(root.transform,false);
    for(int i=0;i<nodes.Length;i++) {
     var s=d.nodes[i];var t=nodes[i].transform;t.localPosition=new Vector3(s.position[0],s.position[1],s.position[2]);t.localRotation=new Quaternion(s.rotation[0],s.rotation[1],s.rotation[2],s.rotation[3]);t.localScale=new Vector3(s.scale[0],s.scale[1],s.scale[2]);
     if(s.matrix.Length==16){var m=new Matrix4x4();for(int k=0;k<16;k++)m[k]=s.matrix[k];t.localPosition=m.GetColumn(3);t.localRotation=m.rotation;t.localScale=m.lossyScale;}
     if(s.mesh<0)continue;
     for(int pi=0;pi<meshes[s.mesh].Length;pi++){var go=new GameObject("surface"+pi);go.transform.SetParent(t,false);go.AddComponent<MeshFilter>().sharedMesh=meshes[s.mesh][pi];go.AddComponent<MeshRenderer>().sharedMaterial=meshMaterials[s.mesh][pi];}
    }
    ctx.AddObjectToAsset("root",root);ctx.SetMainObject(root);
   }
  }
 }
}
