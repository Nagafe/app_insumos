# SGICO - App Gestão de Insumos (Módulo Mobile)

![Status](https://img.shields.io/badge/Status-Finalizado-green)
![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue)
![Supabase](https://img.shields.io/badge/Supabase-Backend-emerald)
![Django](https://img.shields.io/badge/Django-Web_Integration-darkred)

## 📖 Visão Geral

Este repositório contém o Módulo Mobile do **SGICO**, desenvolvido em Flutter. Baseado no nosso Documento de Visão, o sistema foi projetado para modernizar e dar agilidade ao controle de inventário clínico. 

O ecossistema SGICO é composto por uma **Aplicação Web (Django/Python)** para gestão administrativa profunda e por este **Aplicativo Mobile (Flutter)** para acesso tático e rápido "no chão de fábrica". Ambos operam sobre uma base de dados centralizada no **Supabase**.

---

## ⚖️ Comparativo de Arquitetura: App Mobile vs. Aplicação Web

Embora ambos os sistemas manipulem a mesma base de dados (Insumos, Lotes, Movimentações), eles foram desenhados com paradigmas de software distintos para atender às necessidades específicas dos seus usuários.

### 1. Roteamento e Navegação (Rotas)
* **Mobile (Flutter):** O roteamento é **Client-Side** e baseado em pilhas (Stacks). A navegação entre as telas de listagem, movimentação e dashboard ocorre de forma instantânea na memória do dispositivo, sem recarregar a aplicação. O estado da interface é mantido vivo usando o padrão MVVM (Provider).
* **Web (Django):** O roteamento é **Server-Side** (SSR). Cada clique em um menu solicita uma nova rota (`urls.py`) ao servidor, que processa a lógica (`views.py`) e devolve um novo HTML renderizado. É ideal para conexões estáveis em desktops.

### 2. Tela de Movimentações (Entradas e Saídas)
* **No Mobile:** O foco é a **Agilidade**. A interface é simplificada para toques rápidos. O operador pode registrar uma saída no exato momento em que pega o insumo na prateleira. Funciona no modo **Offline-First**, permitindo o registro em áreas da clínica sem sinal de Wi-Fi, armazenando no SQLite e sincronizando depois.
* **Na Web:** O foco é o **Detalhamento e Auditoria**. A tela de movimentações no Django permite lançamento de notas fiscais complexas, entradas em massa (lotes múltiplos) e filtros avançados de busca em todo o histórico da empresa, exigindo conexão constante com a internet.

### 3. Dashboard (Painel Gerencial)
* **No Mobile:** É um **Dashboard Tático**. Desenhado para carregamento em milissegundos usando agregação de dados no próprio SQLite (`SUM`, `COUNT`). Mostra o essencial para decisões rápidas: Patrimônio Total, Itens que precisam de Reposição Urgente e um gráfico simples de evolução de consumo (`fl_chart`).
* **Na Web:** É um **Dashboard Estratégico**. Utiliza o poder de processamento do Python (Pandas/ORM) para gerar relatórios profundos, exportações para PDF/Excel, curvas ABC de estoque e análise de custos por fornecedor.

---

## 🧠 Regras de Negócio e Cálculos

A consistência financeira do estoque é o coração do SGICO. O sistema utiliza a regra do **Custo Médio Ponderado**, que precisa ser calculada de forma idêntica em ambos os nós da aplicação (Mobile e Web).

### Matemática Financeira (Custo Médio e Saldo)
Tanto no aplicativo Flutter (via ViewModel) quanto no backend Django (via Models/Sinais), sempre que uma **ENTRADA** de insumo é registrada, o sistema não apenas soma as quantidades, mas recalcula o valor do patrimônio usando a seguinte regra:

1. **Cálculo do Estoque Antigo:** `(Saldo Geral Atual) * (Custo Médio Atual)`
2. **Cálculo da Nova Compra:** `(Quantidade de Entrada) * (Custo Unitário da Compra)`
3. **Novo Custo Médio:** `(Estoque Antigo + Nova Compra) / (Novo Saldo Geral Total)`

**Tratamento de Saídas:**
Quando ocorre uma **SAÍDA** (consumo do insumo), a regra de negócio determina que o Custo Médio **não se altera**. O sistema apenas subtrai a quantidade do `Saldo Geral`, mantendo o valor histórico do patrimônio intacto.

**Responsabilidade Distribuída:**
* No Django, esse cálculo ocorre transacionalmente no servidor PostgreSQL.
* No Flutter, para garantir o funcionamento offline, o cálculo é feito em Dart e a atualização ocorre simultaneamente em 3 tabelas do SQLite (`insumos`, `lotes`, `movimentacoes`). Assim que a internet volta, os dados já mastigados são validados e replicados no Supabase.

---

## 🔄 Diagrama de Sequência (Sincronização Híbrida)

Para garantir que o cálculo acima nunca quebre, o fluxo de transação do aplicativo segue uma sequência estrita de blindagem de dados:

1. **Ação do Usuário:** Operador regista uma Entrada de Insumo no App.
2. **Processamento (MVVM):** O `MovimentacaoViewModel` resgata o estado mais atualizado do insumo e calcula o Novo Custo Médio em memória.
3. **Transação Local (SQLite):** Os dados são gravados localmente. O status recebe a flag `sincronizado = 0`. Imagens capturadas são convertidas para strings **Base64**, eliminando a dependência de arquivos físicos locais.
4. **Tentativa de Upsert (Supabase):** O `Service` envia o pacote JSON para a nuvem.
    * *Caminho A (Com Internet):* O Supabase processa a inserção. O SQLite marca a flag como `sincronizado = 1`.
    * *Caminho B (Sem Internet):* A transação na nuvem falha silenciosamente. O usuário continua o seu trabalho. Na próxima abertura de tela, a sincronização em background é disparada automaticamente.

---

## 🛠 Tecnologias Utilizadas

* **Frontend Mobile:** Flutter & Dart
* **Gerência de Estado:** Provider (Padrão MVVM - Model-View-ViewModel)
* **Banco de Dados Local:** SQLite (`sqflite` / `sqflite_common_ffi`)
* **Conversão de Mídia:** Base64 (Otimização de armazenamento e sincronização)
* **Gráficos e UI:** `fl_chart`
* **Backend Híbrido:** Supabase (PostgreSQL)
