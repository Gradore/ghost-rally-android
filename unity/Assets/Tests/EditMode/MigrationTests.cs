using NUnit.Framework;
using UnityEngine;
namespace GhostRally.Tests {
 public class MigrationTests {
  [Test] public void AllOriginalChoicesAndWpsArePresent(){var catalog=Catalog.Load();Assert.AreEqual(12,catalog.cars.Length);Assert.AreEqual(20,catalog.tracks.Length);foreach(var stage in catalog.tracks){Assert.Greater(stage.samples.Length,100);Assert.AreEqual(0,stage.samples[0].distance);Assert.AreEqual(stage.length,stage.samples[stage.samples.Length-1].distance,.01f);}}
  [Test] public void AckermannHasCorrectInsideWheel(){var right=DrivingMath.Ackermann(25,2.77f,1.46f);Assert.Greater(right.y,right.x);var left=DrivingMath.Ackermann(-25,2.77f,1.46f);Assert.AreEqual(-right.y,left.x,.001f);Assert.AreEqual(-right.x,left.y,.001f);}
  [Test] public void InputRejectsInvalidAndDriftButKeepsFullLock(){Assert.AreEqual(0,DrivingMath.Axis(float.NaN,.12f));Assert.AreEqual(0,DrivingMath.Axis(.1f,.12f));Assert.AreEqual(1,DrivingMath.Axis(1,.12f));}
  [Test] public void LovoCalibrationAndMeshAreTransferred(){var cal=JsonUtility.FromJson<VehicleCalibration>(Resources.Load<TextAsset>("Migration/Calibration/lovo940voc").text);Assert.AreEqual(1350,cal.mass);Assert.AreEqual(.317f,cal.wheelRadius,.001f);Assert.AreEqual(195,DrivingMath.Torque(cal.torque,4000),.01f);Assert.IsNotNull(Resources.Load<GameObject>("Migration/Geometry/lovo940voc"));}
  [Test] public void NoGodotReplayFingerprintIsAccepted(){Assert.AreEqual("unity-wheel-1",new ReplayData().physics);}
 }
}
