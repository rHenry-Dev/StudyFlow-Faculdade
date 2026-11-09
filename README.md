# StudyFlow

O StudyFlow ajuda a organizar matérias, aulas, anotações, compromissos e mapas
mentais. Você cadastra seu nome e começa a montar seu próprio espaço de estudos.

## Rodar o app

Instale o Flutter 3.47.2 com o Dart 3.13.2. Depois, abra esta pasta no terminal
e rode:

```sh
flutter pub get
flutter run
```

Pra conferir se está tudo certo antes de publicar:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

## Publicar no Vercel

A versão Web pode ser aberta no navegador do celular Android. O GitHub Actions
prepara e publica o site no Vercel depois de rodar as verificações. Assim, o
Flutter fica no ambiente de compilação do GitHub, sem precisar ser instalado no
Vercel.

1. Envie o projeto para um repositório no GitHub. A branch principal deve se
   chamar `main` ou `master`.
2. Crie um projeto no Vercel, mas não conecte a integração automática com o
   GitHub: quem vai fazer a publicação é o fluxo do GitHub Actions.
3. Na pasta do projeto, instale o Vercel CLI, entre na sua conta e conecte a
   pasta ao projeto que criou:

   ```sh
   npm install --global vercel@65.12.1
   vercel login
   vercel link
   ```

4. Abra `.vercel/project.json` e copie os valores de `orgId` e `projectId`.
   Crie estes três segredos no repositório, em **Settings > Secrets and
   variables > Actions**:
   - `VERCEL_TOKEN`: um token criado na sua conta Vercel.
   - `VERCEL_ORG_ID`: o valor de `orgId`.
   - `VERCEL_PROJECT_ID`: o valor de `projectId`.
5. Envie uma alteração para `main` ou `master`. O fluxo **Test and deploy
   StudyFlow Web** roda a formatação, a análise e os testes; se tudo passar,
   publica o site. Também dá pra iniciar o fluxo pela aba **Actions** do
   GitHub.

O arquivo `vercel.json` já informa ao Vercel como compilar o app e servir as
rotas.

## Sobre seus dados e os avisos

Na versão Web, seus dados ficam salvos no navegador e não são enviados para um
servidor. Eles não aparecem automaticamente em outro celular ou navegador.
Apagar os dados do navegador também pode apagar seus estudos.

Os lembretes como notificações do sistema funcionam no app Android instalado,
não no site aberto pelo Vercel. Então, dá pra testar o app pelo navegador do
celular, mas para testar esses avisos é preciso instalar a versão Android. A
tela bloqueada pode ocultar os detalhes dos avisos conforme as configurações de
privacidade do aparelho.
