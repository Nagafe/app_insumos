# SGICO - App Gestão de Insumos (Módulo Mobile)

![Status](https://img.shields.io/badge/Status-Finalizado-green)
![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue)
![Supabase](https://img.shields.io/badge/Supabase-Backend-emerald)
![Django](https://img.shields.io/badge/Django-Web_Integration-darkred)

## 📖 Visão Geral

Este repositório contém o Módulo Mobile do **SGICO**, desenvolvido em Flutter. Baseado no nosso Documento de Visão, o sistema foi projetado para modernizar e dar agilidade ao controle de inventário clínico. 

O ecossistema SGICO é composto por uma **Aplicação Web (Django/Python)** para gestão administrativa profunda e por este **Aplicativo Mobile (Flutter)** para acesso tático e rápido "no chão de fábrica". Ambos operam de forma integrada sobre uma base de dados centralizada no **Supabase**.

---

## 🏛 Arquitetura do Sistema e Conectividade

O núcleo da nossa arquitetura baseia-se na centralização de dados através do **Supabase** (PostgreSQL-as-a-Service), que atua como a única fonte de verdade (Single Source of Truth) conectando as duas pontas do sistema:

1. **Backend as a Service (BaaS):** O Supabase gerencia a autenticação, o armazenamento e a persistência relacional.
2. **Nó Web (Django):** Consome e manipula os dados diretamente no banco para rotinas de back-office.
3. **Nó Mobile (Flutter):** Utiliza uma arquitetura **Offline-First** com banco de dados local (SQLite) para garantir que o fluxo de trabalho nunca pare, sincronizando com o Supabase em background assim que a conexão é restabelecida.

---

## ⚖️ Comparativo de Visão: App Mobile vs. Aplicação Web

Para fins operacionais e de engenharia de software, os dois nós da aplicação dividem responsabilidades de forma clara e intuitiva.

### Tabela Resumida de Características

| Característica | 📱 Módulo Mobile (Flutter) | 💻 Módulo Web (Django) |
| :--- | :--- | :--- |
| **Objetivo Principal** | Acesso rápido, registro "no chão de fábrica". | Gestão completa, auditoria, configurações complexas. |
| **Ambiente de Uso** | Operadores em movimento (estoque, clínica). | Administração em back-office (computador de mesa). |
| **Conectividade** | **Offline-First** (Funciona 100% sem internet via SQLite). | **Online** (Requer conexão ativa com o servidor). |
| **Entrada de Dados** | Focada em agilidade (Entradas/Saídas rápidas, fotos). | Focada em detalhamento (Cadastros em lote, notas fiscais). |
| **Visualização (Dashboard)** | Indicadores imediatos (Patrimônio, Alertas Críticos). | Relatórios profundos, gráficos complexos e exportações. |
| **Sincronização** | Assíncrona (Sincroniza pendências via background). | Síncrona (Ação imediata no banco de dados). |

### Detalhamento dos Componentes

#### 1. Roteamento e Navegação (Rotas)
* **Mobile (Flutter):** O roteamento é **Client-Side** e baseado em pilhas (Stacks). A navegação entre as telas de listagem, movimentação e dashboard ocorre de forma instantânea na memória do dispositivo, sem recarregar a aplicação. O estado da interface é mantido vivo usando o padrão MVVM (Provider).
* **Web (Django):** O roteamento é **Server-Side** (SSR). Cada clique em um menu solicita uma nova rota (`urls.py`) ao servidor, que processa a lógica (`views.py`) e devolve um novo HTML renderizado. É ideal para conexões estáveis em desktops.

#### 2. Tela de Movimentações (Entradas e Saídas)
* **No Mobile:** O foco é a **Agilidade**. A interface é simplificada para toques rápidos. O operador pode registrar uma saída no exato momento em que pega o insumo na prateleira. Funciona no modo **Offline-First**, permitindo o registro em áreas da clínica sem sinal de Wi-Fi, armazenando no SQLite e sincronizando depois.
* **Na Web:** O foco é o **Detalhamento e Auditoria**. A tela de movimentações no Django permite lançamento de notas fiscais complexas, entradas em massa (lotes múltiplos) e filtros avançados de busca em todo o histórico da empresa, exigindo conexão constante com a internet.

#### 3. Dashboard (Painel Gerencial)
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
3. **Transação Local (SQLite):** Os dados são gravados localmente. O status recebe a flag `sincronizado = 0`. Imagens capturadas são convertidas para strings **Base64**, eliminando a dependência de arquivos físicos locais e otimizando o cache interno.
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
