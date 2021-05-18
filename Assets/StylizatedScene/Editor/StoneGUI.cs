////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// xuzheng: 2021/05/18
/// 石头的InspectorGUI Script
////////////////////////////////////////////////////////////////////////////////////////////////////////////

using UnityEngine;
using UnityEditor;

namespace StylizatedScene.Editor
{
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// ShaderGUI
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////
    public class StoneGUI : ShaderGUI
    {
        private MaterialEditor m_materialEditor;
        private Vector3 m_temp = Vector3.up;

        private static bool m_basicShaderSettingsFoldout = false;
        private static bool m_mappingVectorSettingsFoldout = false;

        /// ----------------------------------------------
        /// MaterialPropertys
        /// Base Map
        private MaterialProperty m_baseMap;
        private MaterialProperty m_baseNormalMap;
        private MaterialProperty m_baseColor;
        private MaterialProperty m_mappingMap;
        private MaterialProperty m_mappingNormalMap;
        private MaterialProperty m_mappingColor;
        private MaterialProperty m_mappingMinClip;
        private MaterialProperty m_mappingNormalClip;
        private MaterialProperty m_mappingPower;

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Shader Inspector Utils
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        private void FindProperties(MaterialProperty[] props)
        {
            m_baseMap = FindProperty("_BaseMap", props);
            m_baseNormalMap = FindProperty("_BaseNormalMap", props);
            m_baseColor = FindProperty("_BaseColor", props);
            m_mappingMap = FindProperty("_MappingMap", props);
            m_mappingNormalMap = FindProperty("_MappingNormalMap", props);
            m_mappingColor = FindProperty("_MappingColor", props);
            m_mappingMinClip = FindProperty("_MappingMinClip", props);
            m_mappingNormalClip = FindProperty("_MappingNormalClip", props);
            m_mappingPower = FindProperty("_MappingPower", props);
        }

        private bool Foldout(bool display, string title)
        {
            var _style = new GUIStyle("ShurikenModuleTitle");
            _style.font = new GUIStyle(EditorStyles.boldLabel).font;
            _style.border = new RectOffset(15, 7, 4, 4);
            _style.fixedHeight = 22;
            _style.contentOffset = new Vector2(20f, -2f);
            var _rect = GUILayoutUtility.GetRect(16f, 22f, _style);
            GUI.Box(_rect, title, _style);
            var _event = Event.current;
            var _toggleRect = new Rect(_rect.x + 4f, _rect.y + 2f, 13f, 13f);
            if (_event.type == EventType.Repaint) EditorStyles.foldout.Draw(_toggleRect, false, false, display, false);
            if (_event.type == EventType.MouseDown && _rect.Contains(_event.mousePosition))
            {
                display = !display;
                _event.Use();
            }
            return display;
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Shader Inspector OnGUI
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            m_materialEditor = materialEditor;
            FindProperties(properties);
            Material _material = materialEditor.target as Material;

            EditorGUI.BeginChangeCheck();
            EditorGUILayout.Space();

            m_basicShaderSettingsFoldout = Foldout(m_basicShaderSettingsFoldout, "基础设置");
            if (m_basicShaderSettingsFoldout) BasicSettingGUI(_material);

            m_mappingVectorSettingsFoldout = Foldout(m_mappingVectorSettingsFoldout, "映射设置");
            if (m_mappingVectorSettingsFoldout) MappingVectorSettingsGUI(_material);

            if (EditorGUI.EndChangeCheck()) m_materialEditor.PropertiesChanged();
        }


        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
        /// Shader Inspector OnGUI Item
        ////////////////////////////////////////////////////////////////////////////////////////////////////////////

        private void BasicSettingGUI(Material material)
        {
            EditorGUILayout.BeginVertical("Box");
            m_materialEditor.TextureProperty(m_baseMap, "基础纹理");
            m_materialEditor.TextureProperty(m_baseNormalMap, "法线纹理");
            m_materialEditor.ColorProperty(m_baseColor, "基础颜色");
            EditorGUILayout.EndVertical();
        }

        private void MappingVectorSettingsGUI(Material material)
        {
            EditorGUILayout.BeginVertical("Box");
            float _worldX = material.GetFloat("_MappingVectorX");
            float _worldY = material.GetFloat("_MappingVectorY");
            float _worldZ = material.GetFloat("_MappingVectorZ");
            m_temp.Set(_worldX, _worldY, _worldZ);
            m_materialEditor.TextureProperty(m_mappingMap, "映射纹理");
            m_materialEditor.TextureProperty(m_mappingNormalMap, "映射法线纹理");
            m_materialEditor.ColorProperty(m_mappingColor, "映射颜色");
            m_materialEditor.RangeProperty(m_mappingPower, "Pow(Dot(N, WDir))");
            m_materialEditor.RangeProperty(m_mappingMinClip, "截断的最小值");
            m_materialEditor.RangeProperty(m_mappingNormalClip, "法线权重");
            m_temp = EditorGUILayout.Vector3Field("映射的世界空间矢量", m_temp);
            EditorGUILayout.EndVertical();
            material.SetFloat("_MappingVectorX", m_temp.x);
            material.SetFloat("_MappingVectorY", m_temp.y);
            material.SetFloat("_MappingVectorZ", m_temp.z);
        }
    }
}