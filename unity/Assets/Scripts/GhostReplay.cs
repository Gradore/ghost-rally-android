using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
namespace GhostRally {
 [Serializable] public class ReplayFrame{public float time;public Vector3 position;public Quaternion rotation;}
 [Serializable] public class ReplayData{public string physics="unity-wheel-1",stage,car;public float duration;public List<ReplayFrame> frames=new List<ReplayFrame>();}
 public sealed class GhostReplay:MonoBehaviour{
  ReplayData data;Transform visual;int index;
  public void Configure(ReplayData replay,Transform target){data=replay;visual=target;index=0;}
  public void Seek(float time){if(data==null||visual==null||data.frames.Count<2)return;while(index<data.frames.Count-2&&data.frames[index+1].time<time)index++;var a=data.frames[index];var b=data.frames[index+1];float t=Mathf.InverseLerp(a.time,b.time,time);visual.SetPositionAndRotation(Vector3.Lerp(a.position,b.position,t),Quaternion.Slerp(a.rotation,b.rotation,t));visual.gameObject.SetActive(time<=data.duration);}
  public static string PathFor(string stage,string car)=>Path.Combine(Application.persistentDataPath,"ghost_"+stage+"_"+car+"_unity1.json");
  public static ReplayData Load(string stage,string car){try{string path=PathFor(stage,car);if(!File.Exists(path))return null;var d=JsonUtility.FromJson<ReplayData>(File.ReadAllText(path));if(d==null||d.physics!="unity-wheel-1"||d.stage!=stage||d.car!=car||d.frames==null||d.frames.Count<2)return null;float last=-1;foreach(var frame in d.frames){if(!Finite(frame.time)||frame.time<=last||!Finite(frame.position)||!Finite(frame.rotation))return null;last=frame.time;}return d;}catch(Exception e){Debug.LogWarning("Replay unavailable: "+e.Message);return null;}}
  static bool Finite(float value)=>!float.IsNaN(value)&&!float.IsInfinity(value);
  static bool Finite(Vector3 v)=>Finite(v.x)&&Finite(v.y)&&Finite(v.z);static bool Finite(Quaternion q)=>Finite(q.x)&&Finite(q.y)&&Finite(q.z)&&Finite(q.w);
  public static void Save(ReplayData data){string path=PathFor(data.stage,data.car);string tmp=path+".tmp";File.WriteAllText(tmp,JsonUtility.ToJson(data));if(File.Exists(path))File.Delete(path);File.Move(tmp,path);}
 }
 [Serializable] public class BestEntry{public string key;public float seconds;}
 [Serializable] public class UpgradeEntry{public string car;public int engine,handling,brakes;}
 [Serializable] public class ProgressStore{
  public int rc=300,races;public List<BestEntry> best=new List<BestEntry>();public List<UpgradeEntry> upgrades=new List<UpgradeEntry>();
  public static ProgressStore Load(){try{var s=JsonUtility.FromJson<ProgressStore>(File.ReadAllText(Path.Combine(Application.persistentDataPath,"unity-progress.json")));return s!=null&&s.best!=null&&s.upgrades!=null?s:new ProgressStore();}catch{return new ProgressStore();}}
  public void Save(){File.WriteAllText(Path.Combine(Application.persistentDataPath,"unity-progress.json"),JsonUtility.ToJson(this));}
  public float Best(string key){var b=best.Find(x=>x.key==key);return b==null?0:b.seconds;}
  public UpgradeEntry Upgrade(string car){var u=upgrades.Find(x=>x.car==car);if(u==null){u=new UpgradeEntry{car=car};upgrades.Add(u);}return u;}
  public bool Finish(string key,float time){var b=best.Find(x=>x.key==key);bool pb=b==null||time<b.seconds;if(b==null)best.Add(new BestEntry{key=key,seconds=time});else if(pb)b.seconds=time;races++;rc+=pb?120:80;Save();return pb;}
 }
}
