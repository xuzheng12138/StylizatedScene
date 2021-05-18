using UnityEngine;
using UnityEditor;

namespace LXGrassPatch
{
    [CustomEditor(typeof(GrassPatch))]
    public class GrassPatchEditor : Editor
    {
        private GrassPatch m_comp;
        private void OnEnable() => m_comp = (GrassPatch)target;
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            m_comp.m_color = EditorGUILayout.ColorField("Color", m_comp.m_color);
            if (!Application.isPlaying)
            {
                if (GUILayout.Button("Apply Mesh")) m_comp.RefreshRender();
                m_comp.RefreshColor();
            }
        }
    }
}