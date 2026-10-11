# Zênite

RPG online de evolução e rodadas para jogar com os amigos. Site estático hospedado na Vercel, com login e dados no Supabase.

## Arquivos

- `index.html`: o jogo inteiro
- `config.js`: endereço e chave pública do Supabase
- `supabase.sql`: estrutura do banco de dados

## Instalação

1. **Supabase:** crie o projeto, abra o **SQL Editor**, cole o conteúdo de `supabase.sql` e clique em **Run**.
2. **Supabase → Authentication → Sign In / Providers → Email:** desligue **Confirm email**, para os amigos entrarem logo depois de criar a conta.
3. **config.js:** preencha `supabaseUrl` e `supabaseAnonKey` com os valores de **Project Settings → API**.
4. **GitHub:** envie estes arquivos para o repositório `zenite`.
5. **Vercel:** **Add New → Project**, importe o repositório `zenite` e clique em **Deploy**. Não precisa de configuração de build.

O endereço fica `https://zenite.vercel.app` (ou parecido, se o nome já estiver em uso).
