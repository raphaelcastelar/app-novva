# Preparação do primeiro TestFlight — Novva

Atualizado em 3 de outubro de 2026.

## Estado técnico validado

- nome exibido: `Novva`;
- Bundle ID: `br.com.novva.app`;
- versão inicial: `0.1.0` (`build 1`);
- API: `https://api-novva.inovarcontabilidadex.com.br/api/v1/`;
- mocks bloqueados em builds release;
- comunicação pública exclusivamente por HTTPS;
- manifesto de privacidade incluído no bundle;
- nenhuma permissão sensível do iOS solicitada nesta versão;
- build release sem assinatura gerado com sucesso;
- política e suporte disponíveis publicamente;
- exclusão de conta disponível dentro do app e validada ponta a ponta.

## Endereços para o App Store Connect

```text
Política de Privacidade:
https://api-novva.inovarcontabilidadex.com.br/privacidade

URL de suporte:
https://api-novva.inovarcontabilidadex.com.br/suporte

URL de escolhas de privacidade (opcional):
https://api-novva.inovarcontabilidadex.com.br/privacidade
```

## Cadastro do aplicativo

No Apple Developer e no App Store Connect, usar:

```text
Nome: Novva
Bundle ID explícito: br.com.novva.app
Plataforma: iOS
Idioma principal: Português (Brasil)
SKU sugerido: NOVVA-IOS-001
Categoria sugerida: Finanças
Subtítulo sugerido: Contabilidade para médicos
```

O Bundle ID não pode ser alterado depois que o aplicativo for publicado. Confirme-o antes de criar o registro definitivo.

## Declaração de privacidade

O aplicativo não usa dados para rastreamento e não exibe publicidade. Os dados abaixo são vinculados à identidade e usados para funcionalidade do app:

- nome;
- e-mail;
- telefone;
- identificador do usuário, incluindo CPF usado na autenticação;
- conteúdo enviado pelo usuário, incluindo solicitações e documentos;
- outras informações financeiras, incluindo valores de notas e guias;
- outros dados profissionais e empresariais, como CRM, especialidade, empresa e CNPJ.

As respostas do App Store Connect devem permanecer coerentes com a política pública e com `ios/Runner/PrivacyInfo.xcprivacy`.

## Assinatura no Xcode

1. Abra `ios/Runner.xcworkspace` no Xcode.
2. Selecione o target `Runner`.
3. Abra **Signing & Capabilities**.
4. Mantenha **Automatically manage signing** ativado.
5. Selecione o time da conta Apple Developer.
6. Confirme o Bundle Identifier `br.com.novva.app`.
7. Corrija qualquer conflito de certificado ou provisioning profile apresentado pelo Xcode.

O `DEVELOPMENT_TEAM` depende da conta Apple e não deve ser inventado ou reutilizado de outro aplicativo.

## Build e envio

Validação local sem assinatura:

```bash
./scripts/build_ios_digitalocean.sh --no-codesign
```

Para o envio, abra o workspace no Xcode, selecione **Any iOS Device (arm64)** e execute:

```text
Product → Archive
```

Depois, no Organizer:

```text
Distribute App → App Store Connect → Upload
```

Após o processamento no App Store Connect:

1. associe o build ao TestFlight;
2. informe os dados de export compliance conforme o relatório do próprio upload;
3. cadastre uma conta de demonstração sem dados reais;
4. descreva para a revisão onde encontrar a exclusão da conta: `Mais → Privacidade e conta`;
5. execute o roteiro final em um iPhone físico antes de liberar testadores externos.

## Itens que ainda dependem do titular da conta Apple

- selecionar o time de assinatura no Xcode;
- criar ou confirmar o identificador `br.com.novva.app`;
- criar o aplicativo no App Store Connect;
- preencher classificação etária, descrição, palavras-chave e copyright;
- fornecer screenshots nos tamanhos solicitados pelo App Store Connect;
- preencher e confirmar o formulário de privacidade;
- criar a conta de demonstração da Apple;
- gerar o Archive assinado e enviá-lo.

## Referências oficiais

- https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://developer.apple.com/support/offering-account-deletion-in-your-app
