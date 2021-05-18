using System.Collections.Generic;
using UnityEngine;

namespace LXGrassPatch
{
    [RequireComponent(typeof(MeshFilter))]
    public class GrassPatch : MonoBehaviour
    {
        [HideInInspector] public Color m_color = Color.white;
        public Mesh m_mesh;

        private List<Color> m_verticesColor = new List<Color>();
        private MeshFilter m_meshFilter;
        private Mesh m_meshInstance;
        private MeshFilter meshFilter => GetMeshFilter();


        private MeshFilter GetMeshFilter()
        {
            if (m_meshFilter == null) m_meshFilter = GetComponent<MeshFilter>();
            return m_meshFilter;
        }

        public void RefreshRender()
        {
            if (m_mesh == null) return;
            if (m_meshInstance) DestroyImmediate(m_meshInstance);
            m_meshInstance = Instantiate(m_mesh);
            meshFilter.sharedMesh = m_meshInstance;
        }

        public void RefreshColor()
        {
            if (m_meshInstance)
            {
                m_verticesColor.Clear();
                Mesh _sharedMesh = m_meshFilter.sharedMesh;
                for (int i = 0; i < _sharedMesh.vertices.Length; i++) m_verticesColor.Add(m_color);
                _sharedMesh.colors = m_verticesColor.ToArray();
            }
        }

        private void Update() => RefreshColor();
    }
}