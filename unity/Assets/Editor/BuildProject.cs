using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.Build;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace GhostRally.Editor {
 public static class BuildProject {
  [MenuItem("Ghost Rally/Prepare Unity Android project")]
  public static void Prepare(){
   Directory.CreateDirectory("Assets/Generated");
   var pipeline=AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>("Assets/Generated/MobilePipeline.asset");
   if(pipeline==null){var renderer=ScriptableObject.CreateInstance<UniversalRendererData>();AssetDatabase.CreateAsset(renderer,"Assets/Generated/MobileRenderer.asset");pipeline=UniversalRenderPipelineAsset.Create(renderer);AssetDatabase.CreateAsset(pipeline,"Assets/Generated/MobilePipeline.asset");}
   pipeline.supportsHDR=true;pipeline.msaaSampleCount=2;pipeline.renderScale=.85f;pipeline.shadowDistance=70;pipeline.mainLightShadowmapResolution=2048;pipeline.useSRPBatcher=true;
   GraphicsSettings.defaultRenderPipeline=pipeline;QualitySettings.renderPipeline=pipeline;QualitySettings.vSyncCount=0;QualitySettings.anisotropicFiltering=AnisotropicFiltering.Enable;
   PlayerSettings.companyName="Gradore";PlayerSettings.productName="Ghost Rally Unity Preview";PlayerSettings.bundleVersion="0.1.0-unity";PlayerSettings.Android.bundleVersionCode=1001;PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android,"com.ghostrally.racer.unitypreview");PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android,ScriptingImplementation.IL2CPP);PlayerSettings.Android.targetArchitectures=AndroidArchitecture.ARM64;PlayerSettings.Android.minSdkVersion=AndroidSdkVersions.AndroidApiLevel26;PlayerSettings.Android.targetSdkVersion=AndroidSdkVersions.AndroidApiLevelAuto;PlayerSettings.colorSpace=ColorSpace.Linear;PlayerSettings.defaultInterfaceOrientation=UIOrientation.LandscapeLeft;PlayerSettings.runInBackground=false;
   PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android,false);PlayerSettings.SetGraphicsAPIs(BuildTarget.Android,new[]{GraphicsDeviceType.Vulkan,GraphicsDeviceType.OpenGLES3});
   var settings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);var handler=settings.FindProperty("activeInputHandler");if(handler!=null){handler.intValue=1;settings.ApplyModifiedPropertiesWithoutUndo();}
   var scene=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene,NewSceneMode.Single);var sky=AssetDatabase.LoadAssetAtPath<Material>("Assets/Generated/Sky.mat");if(sky==null){sky=new Material(Shader.Find("Skybox/Procedural"));sky.SetFloat("_SunSize",.035f);sky.SetFloat("_AtmosphereThickness",1.15f);AssetDatabase.CreateAsset(sky,"Assets/Generated/Sky.mat");}RenderSettings.skybox=sky;EditorSceneManager.SaveScene(scene,"Assets/Generated/Bootstrap.unity");EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene("Assets/Generated/Bootstrap.unity",true)};AssetDatabase.SaveAssets();
  }
  [MenuItem("Ghost Rally/Build Android Preview APK")]
  public static void AndroidPreview(){Prepare();Directory.CreateDirectory("Builds");EditorUserBuildSettings.buildAppBundle=false;var result=BuildPipeline.BuildPlayer(new BuildPlayerOptions{scenes=new[]{"Assets/Generated/Bootstrap.unity"},locationPathName="Builds/GhostRally-Unity-preview.apk",target=BuildTarget.Android,options=BuildOptions.Development});if(result.summary.result!=BuildResult.Succeeded)throw new Exception("Unity Android build failed: "+result.summary.result);}
 }
}
