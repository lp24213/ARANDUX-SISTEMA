# Configuração de Armazenamento em Nuvem (R2)

## 📦 Upload de Arquivos para Nuvem - Sem Custos Extras!

O AranduX agora suporta upload de arquivos para **Cloudflare R2**, que oferece:
- ✅ **10GB gratuitos por mês** (sem multa!)
- ✅ Ideal para documentos fiscais, IRPF, comprovantes
- ✅ Sem custos de egress (download gratuito)
- ✅ Alta performance e disponibilidade

## 🚀 Configuração

### 1. Criar Bucket R2 no Cloudflare

1. Acesse o [Dashboard do Cloudflare](https://dash.cloudflare.com)
2. Vá em **R2** → **Create bucket**
3. Nome sugerido: `arandux-files`
4. Escolha a região mais próxima (ex: `us-east-1`)

### 2. Criar API Token para R2

1. Vá em **R2** → **Manage R2 API Tokens**
2. Clique em **Create API Token**
3. Dê permissões de **Object Read & Write**
4. Anote:
   - **Account ID**
   - **Access Key ID**
   - **Secret Access Key**

### 3. Configurar Variáveis de Ambiente

#### Para Produção (Cloudflare Workers):

```bash
# Ativar storage R2
wrangler secret put USE_R2_STORAGE --env production
# Valor: true

# Credenciais R2
wrangler secret put R2_ACCOUNT_ID --env production
# Valor: seu-account-id

wrangler secret put R2_ACCESS_KEY_ID --env production
# Valor: seu-access-key-id

wrangler secret put R2_SECRET_ACCESS_KEY --env production
# Valor: seu-secret-access-key

wrangler secret put R2_BUCKET_NAME --env production
# Valor: arandux-files

wrangler secret put R2_PUBLIC_URL --env production
# Valor: https://pub-{account-id}.r2.dev (ou seu domínio customizado)
```

#### Para Desenvolvimento Local:

Adicione ao `.env`:

```env
USE_R2_STORAGE=true
R2_ACCOUNT_ID=seu-account-id
R2_ACCESS_KEY_ID=seu-access-key-id
R2_SECRET_ACCESS_KEY=seu-secret-access-key
R2_BUCKET_NAME=arandux-files
R2_PUBLIC_URL=https://pub-{account-id}.r2.dev
```

### 4. Criar Tabela no Banco

Execute a migração:

```bash
cd backend
turso db shell <seu-database> < prisma/migrations/add_file_storage.sql
```

Ou via código:

```sql
CREATE TABLE IF NOT EXISTS "FileStorage" (
  "id" TEXT PRIMARY KEY NOT NULL,
  "tenantId" TEXT NOT NULL,
  "fileKey" TEXT NOT NULL,
  "fileUrl" TEXT NOT NULL,
  "fileSize" INTEGER NOT NULL,
  "mimeType" TEXT NOT NULL,
  "folder" TEXT,
  "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS "FileStorage_tenantId_idx" ON "FileStorage"("tenantId");
CREATE INDEX IF NOT EXISTS "FileStorage_fileKey_idx" ON "FileStorage"("fileKey");
```

## 📤 Como Usar

### Upload via API

```bash
POST /api/storage/upload
Content-Type: multipart/form-data

file: [arquivo]
folder: irpf (opcional - para organizar)
```

**Resposta:**
```json
{
  "success": true,
  "message": "Arquivo enviado com sucesso para a nuvem!",
  "data": {
    "url": "https://pub-xxx.r2.dev/tenant-id/irpf/1234567890-documento.pdf",
    "key": "tenant-id/irpf/1234567890-documento.pdf",
    "size": 102400
  }
}
```

### Listar Arquivos

```bash
GET /api/storage/files?folder=irpf
```

### Download

```bash
GET /api/storage/files/{key}
```

### Deletar

```bash
DELETE /api/storage/files/{key}
```

## 💡 Exemplos de Uso

### Upload de Declaração IRPF

```typescript
const formData = new FormData();
formData.append('file', fileBlob, 'irpf-2024.pdf');
formData.append('folder', 'irpf');

const response = await fetch('/api/storage/upload', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
  },
  body: formData,
});
```

### Upload de Documento Fiscal

```typescript
formData.append('folder', 'documentos-fiscais');
```

### Organização por Pasta

- `irpf/` - Declarações de IRPF
- `documentos-fiscais/` - Notas fiscais, recibos
- `comprovantes/` - Comprovantes diversos
- `certificados/` - Certificados digitais

## ⚠️ Limites e Custos

- **Gratuito até 10GB/mês** de armazenamento
- **Gratuito até 1 milhão de operações/mês**
- **Sem custo de egress** (downloads gratuitos)
- Após os limites, custo muito baixo: ~$0.015/GB

## 🔒 Segurança

- Arquivos são isolados por `tenantId`
- Acesso controlado via JWT
- URLs públicas podem ser protegidas com signed URLs (futuro)

## 🎯 Próximos Passos

- [ ] Implementar signed URLs para acesso privado
- [ ] Adicionar compressão automática de imagens
- [ ] Integração com frontend (componente de upload)
- [ ] Preview de arquivos (PDF, imagens)
- [ ] Quota por tenant baseada no plano
