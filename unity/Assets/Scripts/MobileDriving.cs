using System.Collections.Generic;
using UnityEngine;
using UnityEngine.InputSystem;
namespace GhostRally {
 public sealed class MobileDriving:MonoBehaviour {
  public RallyVehicle vehicle;public bool active,autoGas,tilt;public float sensitivity=1,deadzone=.03f,thumbTravel=.085f,response=1;public bool invertTilt;float tiltNeutral,filtered;readonly Dictionary<int,Vector2> anchors=new Dictionary<int,Vector2>();
  void OnEnable(){if(Accelerometer.current!=null)InputSystem.EnableDevice(Accelerometer.current);}
  public void Calibrate(){if(Accelerometer.current!=null)tiltNeutral=Accelerometer.current.acceleration.ReadValue().x;}
  public void Clear(){anchors.Clear();filtered=0;if(vehicle!=null){vehicle.steer=vehicle.throttle=vehicle.brake=0;vehicle.handbrake=false;}}
  void Update(){if(!active||vehicle==null)return;float steer=0,gas=0,brake=0;bool hand=false,analog=false;
   var keyboard=Keyboard.current;if(keyboard!=null){steer=(keyboard.dKey.isPressed||keyboard.rightArrowKey.isPressed?1:0)-(keyboard.aKey.isPressed||keyboard.leftArrowKey.isPressed?1:0);gas=keyboard.wKey.isPressed||keyboard.upArrowKey.isPressed?1:0;brake=keyboard.sKey.isPressed||keyboard.downArrowKey.isPressed?1:0;hand=keyboard.spaceKey.isPressed;}
   var touchscreen=Touchscreen.current;if(touchscreen!=null)foreach(var finger in touchscreen.touches){int id=finger.touchId.ReadValue();Vector2 p=finger.position.ReadValue();if(!finger.press.isPressed){anchors.Remove(id);continue;}if(!anchors.TryGetValue(id,out Vector2 anchor)){anchor=p;anchors[id]=anchor;}float x=anchor.x/Screen.width,y=anchor.y/Screen.height;
    if(y>.36f)continue; // Input System screen origin is bottom-left.
    if(x<.27f)steer=DrivingMath.Axis((p.x-anchor.x)/(Screen.width*thumbTravel),deadzone);
    else if(x>.73f){if(y>.29f){hand=true;continue;}analog=true;float amount=DrivingMath.Axis((p.y-anchor.y)/(Screen.height*.09f),.06f);gas=Mathf.Max(gas,Mathf.Max(0,amount));brake=Mathf.Max(brake,Mathf.Max(0,-amount));}
   }
   if(tilt&&Accelerometer.current!=null){float value=(Accelerometer.current.acceleration.ReadValue().x-tiltNeutral)/.4f;steer=DrivingMath.Axis(invertTilt?-value:value,.06f);}
   var pad=Gamepad.current;if(pad!=null){float axis=DrivingMath.Axis(pad.leftStick.x.ReadValue(),.12f);if(axis!=0)steer=axis;gas=Mathf.Max(gas,pad.rightTrigger.ReadValue());brake=Mathf.Max(brake,pad.leftTrigger.ReadValue());hand|=pad.buttonSouth.isPressed;analog=true;}
   if(autoGas&&!analog&&brake<.05f&&!hand)gas=1;
   float target=Mathf.Clamp(steer*sensitivity,-1,1);filtered=Mathf.Lerp(filtered,target,1-Mathf.Exp(-24*response*Time.deltaTime));vehicle.steer=filtered;vehicle.throttle=gas;vehicle.brake=brake;vehicle.handbrake=hand;
  }
 }
}
