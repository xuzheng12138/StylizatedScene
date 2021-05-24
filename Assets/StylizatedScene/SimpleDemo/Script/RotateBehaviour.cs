using UnityEngine;

public class RotateBehaviour : MonoBehaviour
{
    public float m_speed;
    public float m_sy;
    Vector3 m_e;
    private void Update()
    {
        m_e = transform.eulerAngles;
        m_e.y += Time.deltaTime * m_speed * m_sy;
        transform.eulerAngles = m_e;
    }
}
