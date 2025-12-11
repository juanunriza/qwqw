import supabaseAdmin from '../../lib/supabaseServer'

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' })

  const { user_id } = req.body || {}
  if (!user_id) return res.status(400).json({ error: 'Missing user_id in body' })

  try {
    // Example seed: add a couple of categories and an account for the provided user
    await supabaseAdmin.from('accounts').insert([
      { user_id, name: 'Wallet', currency: 'USD', initial_balance: 100 },
      { user_id, name: 'Checking', currency: 'USD', initial_balance: 500 },
    ])

    await supabaseAdmin.from('categories').insert([
      { user_id, name: 'Groceries', type: 'expense' },
      { user_id, name: 'Salary', type: 'income' },
    ])

    return res.status(200).json({ ok: true })
  } catch (err) {
    return res.status(500).json({ error: err.message || err })
  }
}
