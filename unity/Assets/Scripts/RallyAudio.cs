using UnityEngine;
namespace GhostRally {
 public sealed class RallyAudio:MonoBehaviour{
  public RallyVehicle vehicle;AudioSource engine,skid;
  void Start(){engine=gameObject.AddComponent<AudioSource>();engine.clip=Resources.Load<AudioClip>("Migration/Audio/recorded_engine");if(engine.clip==null)engine.clip=Resources.Load<AudioClip>("Migration/Audio/engine_cc0");engine.loop=true;engine.spatialBlend=0;engine.volume=.35f;if(engine.clip!=null)engine.Play();skid=gameObject.AddComponent<AudioSource>();}
  void Update(){if(engine==null||vehicle==null)return;engine.pitch=Mathf.Clamp(vehicle.Rpm/2200,.6f,2.8f);engine.volume=Mathf.Lerp(engine.volume,vehicle.Body.isKinematic?0:.12f+vehicle.throttle*.3f,1-Mathf.Exp(-8*Time.unscaledDeltaTime));}
 }
}
