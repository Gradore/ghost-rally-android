using UnityEngine;
namespace GhostRally {
 public sealed class RallyCamera:MonoBehaviour {
  public RallyVehicle vehicle;public bool cockpit;float reverseYaw;Vector3 velocity;
  void LateUpdate(){if(vehicle==null||vehicle.Body==null)return;float local=Vector3.Dot(vehicle.Body.linearVelocity,vehicle.transform.forward);float target=local<-.8f?180:local>.8f?0:reverseYaw;reverseYaw=Mathf.LerpAngle(reverseYaw,target,1-Mathf.Exp(-3*Time.unscaledDeltaTime));
   var t=vehicle.transform;if(cockpit){transform.position=t.TransformPoint(new Vector3(-.32f,1.14f,.3f));transform.rotation=Quaternion.Slerp(transform.rotation,t.rotation,1-Mathf.Exp(-16*Time.unscaledDeltaTime));return;}
   var orientation=t.rotation*Quaternion.Euler(0,reverseYaw,0);Vector3 look=t.position+Vector3.up*.9f;Vector3 desired=t.position+orientation*new Vector3(0,2.3f,-6.5f);Vector3 delta=desired-look;
   if(Physics.SphereCast(look,.25f,delta.normalized,out RaycastHit hit,delta.magnitude,~(1<<8),QueryTriggerInteraction.Ignore))desired=hit.point+hit.normal*.35f;
   transform.position=Vector3.SmoothDamp(transform.position,desired,ref velocity,.09f,100,Time.unscaledDeltaTime);transform.LookAt(look+t.forward*2);GetComponent<Camera>().fieldOfView=Mathf.Lerp(62,74,Mathf.Clamp01(vehicle.Speed/50));
  }
 }
}
