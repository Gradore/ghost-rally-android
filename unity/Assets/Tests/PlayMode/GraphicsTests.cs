using System.Collections;
using System.IO;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.TestTools;

namespace GhostRally.Tests {
 public sealed class GraphicsTests {
  GameObject car,world,cameraObject;
  RenderTexture target;
  Texture2D capture;

  [UnityTest]
  public IEnumerator LovoAndMappedRostockStartRenderWithoutMissingShaders() {
   Assert.AreNotEqual(GraphicsDeviceType.Null,SystemInfo.graphicsDeviceType,
    "Graphics acceptance requires a real or software graphics device; do not run PlayMode with -nographics");
   var catalog=Catalog.Load();
   var stage=System.Array.Find(catalog.tracks,s=>s.routeIndex==16);
   Assert.IsNotNull(stage);
   var prefab=Resources.Load<GameObject>("Migration/Geometry/lovo940voc");
   Assert.IsNotNull(prefab);
   car=Object.Instantiate(prefab);
   world=new GameObject("Rostock graphics acceptance");
   var mapped=world.AddComponent<StageWorld>();
   mapped.Build(stage,car.transform);
   car.transform.SetPositionAndRotation(mapped.At(4)+Vector3.up*.1f,mapped.Heading(4));
   cameraObject=new GameObject("Acceptance camera");
   var camera=cameraObject.AddComponent<Camera>();
   camera.transform.position=car.transform.TransformPoint(new Vector3(4,2.4f,-6));
   camera.transform.LookAt(car.transform.position+Vector3.up*.8f);
   camera.nearClipPlane=.15f;
   camera.farClipPlane=1200;
   camera.fieldOfView=62;
   camera.clearFlags=CameraClearFlags.SolidColor;
   camera.backgroundColor=new Color(.04f,.07f,.12f);
   target=new RenderTexture(640,360,24,RenderTextureFormat.ARGB32);
   target.Create();
   camera.targetTexture=target;
   // Camera target rendering continues in batch mode; WaitForEndOfFrame does not.
   for(int i=0;i<10;i++)yield return null;
   var previous=RenderTexture.active;
   capture=new Texture2D(640,360,TextureFormat.RGB24,false);
   try{RenderTexture.active=target;capture.ReadPixels(new Rect(0,0,640,360),0,0);capture.Apply();}
   finally{RenderTexture.active=previous;}
   var pixels=capture.GetPixels32();
   int magenta=0,min=255,max=0;
   foreach(var p in pixels){if(p.r>180&&p.b>180&&p.g<80)magenta++;int brightness=(p.r+p.g+p.b)/3;min=Mathf.Min(min,brightness);max=Mathf.Max(max,brightness);}
   Assert.Greater(max-min,25,"Captured frame must contain scene detail instead of a blank render target");
   Assert.Less(magenta,pixels.Length/100,"Missing shader magenta must not dominate the captured scene");
   string logs=Path.GetFullPath(Path.Combine(Application.dataPath,"../Logs"));
   Directory.CreateDirectory(logs);
   File.WriteAllBytes(Path.Combine(logs,"Unity-Rostock-Lovo-render.png"),capture.EncodeToPNG());
   LogAssert.NoUnexpectedReceived();
  }

  [UnityTearDown]
  public IEnumerator Cleanup() {
   if(cameraObject!=null)Object.Destroy(cameraObject);
   if(car!=null)Object.Destroy(car);
   if(world!=null)Object.Destroy(world);
   if(capture!=null)Object.Destroy(capture);
   if(target!=null){target.Release();Object.Destroy(target);}
   yield return null;
  }
 }
}
