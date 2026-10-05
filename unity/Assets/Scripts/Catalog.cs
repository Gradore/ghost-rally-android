using System;
using UnityEngine;
namespace GhostRally {
 [Serializable] public class CarSpec { public string id,name,drive,color;public float mass,power,top,wheelbase,wheel_radius,front_weight,final_drive;public bool voc; }
 [Serializable] public class RoadSample {public float x,y,z,distance,width;public bool gravel;public Vector3 Position=>new Vector3(x,y,z);}
 [Serializable] public class StageSpec {public string id,name,surface;public int routeIndex,wp;public float length;public double originLat,originLon,rotation;public RoadSample[] samples;}
 [Serializable] public class Catalog {public CarSpec[] cars;public StageSpec[] tracks;public string physicsVersion;public static Catalog Load()=>JsonUtility.FromJson<Catalog>(Resources.Load<TextAsset>("Migration/catalog").text);}
 [Serializable] public class TorquePoint {public float rpm,torque;}
 [Serializable] public class VehicleCalibration {public bool assumption;public float mass,wheelbase,track,cgHeight,frontFraction,wheelRadius,finalDrive,redline,shiftUp,drag,efficiency,spring,damper,steeringLock;public float[] gears;public TorquePoint[] torque;}
 public static class DrivingMath {
  public static float Axis(float value,float deadzone){if(float.IsNaN(value)||float.IsInfinity(value))return 0;deadzone=Mathf.Clamp(deadzone,0,.4f);return Mathf.Sign(value)*Mathf.Clamp01((Mathf.Abs(value)-deadzone)/(1-deadzone));}
  public static Vector2 Ackermann(float angle,float wheelbase,float track){if(Mathf.Abs(angle)<.001f)return Vector2.zero;float radius=wheelbase/Mathf.Tan(Mathf.Abs(angle)*Mathf.Deg2Rad);float inner=Mathf.Atan(wheelbase/Mathf.Max(.01f,radius-track*.5f))*Mathf.Rad2Deg;float outer=Mathf.Atan(wheelbase/(radius+track*.5f))*Mathf.Rad2Deg;return angle<0?new Vector2(-inner,-outer):new Vector2(outer,inner);}
  public static float Torque(TorquePoint[] points,float rpm){for(int i=1;i<points.Length;i++)if(rpm<=points[i].rpm)return Mathf.Lerp(points[i-1].torque,points[i].torque,Mathf.InverseLerp(points[i-1].rpm,points[i].rpm,rpm));return points[points.Length-1].torque;}
 }
}
