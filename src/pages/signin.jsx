import { useState } from 'react'
import { supabase } from '../lib/supabaseClient'

export default function SignIn() {
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')

  async function handleSubmit(e) {
    e.preventDefault()
    setLoading(true)
    setMessage('')
    const { error } = await supabase.auth.signInWithOtp({ email })
    setLoading(false)
    if (error) setMessage(error.message)
    else setMessage('Se ha enviado un enlace mágico a tu correo.')
  }

  return (
    <div style={{maxWidth:480, margin:'48px auto', fontFamily:'system-ui, sans-serif'}}>
      <h2>Iniciar sesión</h2>
      <form onSubmit={handleSubmit}>
        <label style={{display:'block', marginBottom:8}}>Correo</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          style={{width:'100%', padding:8, marginBottom:12}}
        />
        <button type="submit" disabled={loading} style={{padding:'8px 12px'}}>
          {loading ? 'Enviando...' : 'Enviar enlace mágico'}
        </button>
      </form>
      {message && <p style={{marginTop:12}}>{message}</p>}
      <p style={{marginTop:16, color:'#666'}}>
        Nota: se usa Magic Link; asegúrate de configurar plantillas de correo en Supabase Auth.
      </p>
    </div>
  )
}
