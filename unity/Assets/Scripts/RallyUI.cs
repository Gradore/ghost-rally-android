using System;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.InputSystem.UI;
using UnityEngine.UI;
namespace GhostRally {
 public sealed class RallyUI:MonoBehaviour{
  public RectTransform root;public Font font;public Color accent=new Color(.93f,.72f,.24f);public readonly Color panel=new Color(.025f,.055f,.075f,.92f);
  void Awake(){font=Resources.Load<Font>("Migration/Fonts/Rajdhani-Medium");if(font==null)font=Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");var canvas=gameObject.AddComponent<Canvas>();canvas.renderMode=RenderMode.ScreenSpaceOverlay;gameObject.AddComponent<GraphicRaycaster>();var scale=gameObject.AddComponent<CanvasScaler>();scale.uiScaleMode=CanvasScaler.ScaleMode.ScaleWithScreenSize;scale.referenceResolution=new Vector2(1280,720);scale.matchWidthOrHeight=.5f;
   root=new GameObject("Safe area",typeof(RectTransform)).GetComponent<RectTransform>();root.SetParent(transform,false);UpdateSafeArea();if(FindFirstObjectByType<EventSystem>()==null){var events=new GameObject("EventSystem");events.AddComponent<EventSystem>();events.AddComponent<InputSystemUIInputModule>();}
  }
  void Update(){UpdateSafeArea();}
  void UpdateSafeArea(){if(root==null)return;var a=Screen.safeArea;root.anchorMin=new Vector2(a.x/Screen.width,a.y/Screen.height);root.anchorMax=new Vector2(a.xMax/Screen.width,a.yMax/Screen.height);root.offsetMin=root.offsetMax=Vector2.zero;}
  public void Clear(){foreach(Transform child in root){child.gameObject.SetActive(false);Destroy(child.gameObject);}}
  public RectTransform Rect(string name,Transform parent,float x,float y,float w,float h){var r=new GameObject(name,typeof(RectTransform)).GetComponent<RectTransform>();r.SetParent(parent,false);r.anchorMin=r.anchorMax=new Vector2(0,1);r.pivot=new Vector2(0,1);r.anchoredPosition=new Vector2(x,-y);r.sizeDelta=new Vector2(w,h);return r;}
  public Text Label(Transform parent,string text,float x,float y,float w,float h,int size=24,Color? color=null){var r=Rect("Text",parent,x,y,w,h);var t=r.gameObject.AddComponent<Text>();t.font=font;t.text=text;t.fontSize=size;t.color=color??Color.white;t.raycastTarget=false;t.verticalOverflow=VerticalWrapMode.Overflow;return t;}
  public RectTransform Panel(Transform parent,float x,float y,float w,float h){var r=Rect("Panel",parent,x,y,w,h);r.gameObject.AddComponent<Image>().color=panel;return r;}
  public Button Button(Transform parent,string title,float x,float y,float w,float h,Action action,bool primary=false){var r=Rect(title,parent,x,y,w,h);var image=r.gameObject.AddComponent<Image>();image.color=primary?accent:new Color(.09f,.15f,.18f,.95f);var b=r.gameObject.AddComponent<Button>();b.targetGraphic=image;var t=Label(r,title,10,0,w-20,h,22,primary?new Color(.025f,.05f,.06f):Color.white);t.alignment=TextAnchor.MiddleCenter;b.onClick.AddListener(()=>action());return b;}
  public RectTransform ScrollList(float x,float y,float w,float h,int items){var outer=Panel(root,x,y,w,h);var scroll=outer.gameObject.AddComponent<ScrollRect>();scroll.horizontal=false;var view=Rect("Viewport",outer,0,0,w,h);view.gameObject.AddComponent<Image>().color=panel;view.gameObject.AddComponent<Mask>().showMaskGraphic=false;var content=Rect("Content",view,0,0,w,items*54);scroll.viewport=view;scroll.content=content;scroll.movementType=ScrollRect.MovementType.Clamped;return content;}
 }
}
