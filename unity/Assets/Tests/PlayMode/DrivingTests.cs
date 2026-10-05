using System.Collections;
using NUnit.Framework;
using UnityEngine;
using UnityEngine.TestTools;

namespace GhostRally.Tests {
 public sealed class DrivingTests {
  GameObject car,ground;
  float previousStep;

  [UnityTest]
  public IEnumerator LovoSettlesAcceleratesAndBrakesOnAsphalt() {
   previousStep=Time.fixedDeltaTime;
   Time.fixedDeltaTime=1f/120;
   ground=GameObject.CreatePrimitive(PrimitiveType.Cube);
   ground.transform.position=new Vector3(10000,-.5f,0);
   ground.transform.localScale=new Vector3(100,1,500);
   ground.AddComponent<RallySurface>();
   car=new GameObject("Lovo physics acceptance");
   car.transform.position=new Vector3(10000,.15f,0);
   var chassis=car.AddComponent<BoxCollider>();
   chassis.center=new Vector3(0,.82f,0);
   chassis.size=new Vector3(1.65f,1.1f,4.6f);
   var vehicle=car.AddComponent<RallyVehicle>();
   var catalog=Catalog.Load();
   var spec=System.Array.Find(catalog.cars,c=>c.id=="lovo940voc");
   var calibration=JsonUtility.FromJson<VehicleCalibration>(Resources.Load<TextAsset>("Migration/Calibration/lovo940voc").text);
   vehicle.Configure(spec,calibration);
   for(int i=0;i<120;i++)yield return new WaitForFixedUpdate();
   foreach(var wheel in vehicle.wheels)Assert.IsTrue(wheel.GetGroundHit(out _),"Wheel must contact the road after settling");
   vehicle.throttle=1;
   for(int i=0;i<360;i++)yield return new WaitForFixedUpdate();
   float speed=vehicle.Speed;
   Assert.Greater(speed,3,"The migrated car must move under its own engine torque");
   Assert.Greater(car.transform.position.z,3,"Positive throttle must drive forwards");
   vehicle.throttle=0;
   vehicle.brake=1;
   for(int i=0;i<240;i++)yield return new WaitForFixedUpdate();
   Assert.Less(vehicle.Speed,speed*.5f,"Service brakes must reduce speed");
   Assert.Less(Mathf.Abs(car.transform.position.y),2,"The chassis must remain on the test road");
   LogAssert.NoUnexpectedReceived();
  }

  [UnityTearDown]
  public IEnumerator Cleanup() {
   if(car!=null)Object.Destroy(car);
   if(ground!=null)Object.Destroy(ground);
   Time.fixedDeltaTime=previousStep;
   yield return null;
  }
 }
}
