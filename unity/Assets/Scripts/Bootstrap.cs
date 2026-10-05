using UnityEngine;
namespace GhostRally {
 public static class Bootstrap {
  [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
  static void Start(){if(Object.FindFirstObjectByType<RallySession>()==null)new GameObject("Ghost Rally").AddComponent<RallySession>().Initialize();}
 }
}
