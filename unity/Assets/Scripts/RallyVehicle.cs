using UnityEngine;
namespace GhostRally {
 [RequireComponent(typeof(Rigidbody))]
 public sealed class RallyVehicle:MonoBehaviour {
  public WheelCollider[] wheels=new WheelCollider[4];public Transform[] wheelVisuals=new Transform[4];public VehicleCalibration calibration;public CarSpec spec;
  public float steer,throttle,brake;public bool handbrake,abs=true,tractionControl=true;public float brakeScale=1;public Rigidbody Body{get;private set;}public float Speed=>Body.linearVelocity.magnitude;public float Rpm{get;private set;}=900;public int Gear{get;private set;}=1;
  float steeringAngle;bool reverse,brakeWasDown;Quaternion[] baseWheelRotation=new Quaternion[4];
  public void Configure(CarSpec car,VehicleCalibration config){
   spec=car;calibration=config;Body=GetComponent<Rigidbody>();Body.mass=config.mass;Body.interpolation=RigidbodyInterpolation.Interpolate;Body.collisionDetectionMode=CollisionDetectionMode.ContinuousDynamic;Body.centerOfMass=new Vector3(0,config.cgHeight,config.wheelbase*(config.frontFraction-.5f));
   Body.solverIterations=12;Body.solverVelocityIterations=4;
   for(int i=0;i<4;i++){
    var go=new GameObject("WheelPhysics"+i);go.transform.SetParent(transform,false);go.transform.localPosition=new Vector3((i%2==0?-1:1)*config.track*.5f,config.wheelRadius+.12f,(i<2?1:-1)*config.wheelbase*.5f);
    var w=go.AddComponent<WheelCollider>();w.radius=config.wheelRadius;w.mass=20;w.suspensionDistance=.24f;w.sprungMass=config.mass*(i<2?config.frontFraction:1-config.frontFraction)*.5f;w.forceAppPointDistance=.25f;
    w.suspensionSpring=new JointSpring{spring=config.spring,damper=config.damper,targetPosition=.5f};w.wheelDampingRate=.4f;wheels[i]=w;
    if(wheelVisuals[i]!=null)baseWheelRotation[i]=wheelVisuals[i].localRotation;
   }
   wheels[0].ConfigureVehicleSubsteps(8,4,3);
  }
  void FixedUpdate(){
   if(Body==null||calibration==null)return;var c=calibration;float localSpeed=Vector3.Dot(Body.linearVelocity,transform.forward);bool down=brake>.1f;
   if(!down||throttle>.1f)reverse=false;else if(!brakeWasDown&&Mathf.Abs(localSpeed)<.3f&&!handbrake)reverse=true;brakeWasDown=down;
   float demand=reverse?brake:throttle;float serviceBrake=reverse?0:brake;
   float rpmSum=0;int driven=0;for(int i=0;i<4;i++)if(IsDriven(i)){rpmSum+=Mathf.Abs(wheels[i].rpm);driven++;}
   Rpm=Mathf.Max(900,rpmSum/Mathf.Max(1,driven)*c.finalDrive*(reverse?c.gears[0]:c.gears[Gear-1]));
   if(!reverse){if(Rpm>c.shiftUp&&Gear<c.gears.Length)Gear++;else if(Rpm<1800&&Gear>1)Gear--;}
   float engine=DrivingMath.Torque(c.torque,Mathf.Min(Rpm,c.redline))*demand*(Rpm>=c.redline?0:1);
   float axle=engine*(reverse?-c.gears[0]:c.gears[Gear-1])*c.finalDrive*c.efficiency;
   float limit=Mathf.Lerp(c.steeringLock,10,Mathf.InverseLerp(12,45,Speed));steeringAngle=Mathf.MoveTowards(steeringAngle,steer*limit,275*Time.fixedDeltaTime);var angles=DrivingMath.Ackermann(steeringAngle,c.wheelbase,c.track);
   wheels[0].steerAngle=angles.x;wheels[1].steerAngle=angles.y;
   for(int i=0;i<4;i++){
    var w=wheels[i];WheelHit hit;bool ground=w.GetGroundHit(out hit);var road=ground?hit.collider.GetComponent<RallySurface>():null;bool gravel=road!=null&&road.gravel;float grip=road==null?.45f:gravel?.72f:1f;
    SetFriction(w,grip,gravel);float drive=IsDriven(i)?axle/Mathf.Max(1,driven):0;
    if(tractionControl&&ground&&Mathf.Abs(hit.forwardSlip)>.18f)drive*=Mathf.Clamp01(.18f/Mathf.Abs(hit.forwardSlip));w.motorTorque=drive;
    float torque=serviceBrake*brakeScale*c.mass*9.5f*c.wheelRadius*(i<2?.3f:.2f);
    if(abs&&ground&&Mathf.Abs(hit.forwardSlip)>.22f&&Speed>2)torque*=.35f;
    w.brakeTorque=(handbrake&&i>=2)?2500:torque;
   }
   AntiRoll(0,1);AntiRoll(2,3);var v=Body.linearVelocity;Body.AddForce(-v*v.magnitude*c.drag,ForceMode.Force);
  }
  bool IsDriven(int i)=>spec.drive=="AWD"||(spec.drive=="FWD"?i<2:i>=2);
  void SetFriction(WheelCollider w,float grip,bool gravel){var f=w.forwardFriction;f.extremumSlip=gravel?.2f:.12f;f.extremumValue=1;f.asymptoteSlip=.8f;f.asymptoteValue=.6f;f.stiffness=grip;w.forwardFriction=f;f=w.sidewaysFriction;f.extremumSlip=gravel?.16f:.09f;f.extremumValue=1;f.asymptoteSlip=.5f;f.asymptoteValue=.65f;f.stiffness=grip;w.sidewaysFriction=f;}
  void AntiRoll(int left,int right){WheelHit a,b;bool ga=wheels[left].GetGroundHit(out a),gb=wheels[right].GetGroundHit(out b);if(!ga&&!gb)return;float ta=ga?(-wheels[left].transform.InverseTransformPoint(a.point).y-wheels[left].radius)/wheels[left].suspensionDistance:1;float tb=gb?(-wheels[right].transform.InverseTransformPoint(b.point).y-wheels[right].radius)/wheels[right].suspensionDistance:1;float force=(ta-tb)*10000;if(ga)Body.AddForceAtPosition(-transform.up*force,wheels[left].transform.position);if(gb)Body.AddForceAtPosition(transform.up*force,wheels[right].transform.position);}
  void LateUpdate(){if(Body==null)return;for(int i=0;i<4;i++)if(wheelVisuals[i]!=null){wheels[i].GetWorldPose(out Vector3 p,out Quaternion q);wheelVisuals[i].position=p;wheelVisuals[i].rotation=q*baseWheelRotation[i];}}
  public void ResetTo(Vector3 p,Quaternion q){if(!Body.isKinematic){Body.linearVelocity=Vector3.zero;Body.angularVelocity=Vector3.zero;}Body.position=p;Body.rotation=q;steer=throttle=brake=0;handbrake=false;reverse=brakeWasDown=false;Gear=1;steeringAngle=0;}
 }
 public sealed class RallySurface:MonoBehaviour{public bool gravel;}
}
