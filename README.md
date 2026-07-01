# SGICO - App Gestão de Insumos (Módulo Mobile)

![Status](https://img.shields.io/badge/Status-Finalizado-green)
![Flutter](https://img.shields.io/badge/Flutter-Mobile-blue)
![Supabase](https://img.shields.io/badge/Supabase-Backend-emerald)
![Django](https://img.shields.io/badge/Django-Web_Integration-darkred)

## 📖 Visão Geral

Este repositório contém o Módulo Mobile do **SGICO**, desenvolvido em Flutter. Baseado no nosso Documento de Visão, o sistema foi projetado para modernizar e dar agilidade ao controle de inventário clínico. 

O grande diferencial desta arquitetura é a sua natureza distribuída: o ecossistema é composto por uma **Aplicação Web (Django/Python)** para gestão administrativa profunda e por este **Aplicativo Mobile (Flutter)** para acesso tático e rápido. Ambos operam sobre uma base de dados centralizada e em tempo real.

---

## 🏛 Arquitetura do Sistema e Conectividade

O núcleo da nossa arquitetura baseia-se na centralização de dados através do **Supabase** (PostgreSQL-as-a-Service), que atua como a única fonte de verdade (Single Source of Truth) conectando as duas pontas do sistema:

1. **Backend as a Service (BaaS):** O Supabase gerencia a autenticação, o armazenamento de imagens (via conversão Base64 para otimização de cache) e a persistência relacional.
2. **Nó Web (Django):** Consome e manipula os dados diretamente no banco para rotinas de back-office.
3. **Nó Mobile (Flutter):** Utiliza uma arquitetura **Offline-First** com banco de dados local (SQLite) para garantir que o fluxo de trabalho nunca pare, sincronizando com o Supabase em background assim que a conexão é restabelecida.

---

## ⚖️ Comparativo: App Mobile vs. Aplicação Web (Django)

Embora ambos os sistemas manipulem a mesma base de dados (Insumos, Lotes, Movimentações), eles foram desenhados para casos de uso e contextos operacionais distintos, respeitando princípios de separação de responsabilidades.

| Característica | 📱 Módulo Mobile (Flutter) | 💻 Módulo Web (Django) |
| :--- | :--- | :--- |
| **Objetivo Principal** | Acesso rápido, registro "no chão de fábrica". | Gestão completa, auditoria, configurações complexas. |
| **Ambiente de Uso** | Operadores em movimento (estoque, clínica). | Administração em back-office (computador de mesa). |
| **Conectividade** | **Offline-First** (Funciona 100% sem internet via SQLite). | **Online** (Requer conexão ativa com o servidor). |
| **Entrada de Dados** | Focada em agilidade (Entradas/Saídas rápidas, fotos). | Focada em detalhamento (Cadastros em lote, notas fiscais). |
| **Visualização (Dashboard)** | Indicadores imediatos (Patrimônio, Alertas Críticos). | Relatórios profundos, gráficos complexos e exportações. |
| **Sincronização** | Assíncrona (Sincroniza pendências via background). | Síncrona (Ação imediata no banco de dados). |

---

## ⚙️ Principais Casos de Uso (Mobile)

* **UC01 - Gestão Híbrida de Insumos:** Cadastro, edição e exclusão de itens de inventário com suporte a imagens convertidas em Base64, garantindo disponibilidade offline.
* **UC02 - Registro de Movimentações:** Lançamento ágil de ENTRADA e SAÍDA de materiais, com cálculo automatizado e em tempo real do **Custo Médio** e **Saldo Geral**.
* **UC03 - Dashboard Tático:** Painel gerencial de carregamento instantâneo apresentando o Valor Total do Patrimônio, Alertas de Reposição Urgente e Gráficos de Consumo Mensal.

---

## 🔄 Diagrama de Sequência (Fluxo de Sincronização)

Para garantir a confiabilidade matemática exigida pelo Custo Médio e Saldo de Estoque, o fluxo de transação do aplicativo segue a seguinte sequência lógica:

1. **Ação do Usuário:** Operador regista uma Entrada de Insumo no App.
2. **Cálculo Local:** O ViewModel processa a regra de negócio (Cálculo do novo Custo Médio).
3. **Transação SQLite:** Os dados (Movimentação, Lote, Saldo Atualizado) são salvos no banco local (`insumos.db`). O status recebe a flag `sincronizado = 0`.
4. **Tentativa de Sincronização:** O `Service` tenta enviar o JSON completo (incluindo imagens em Base64) para o Supabase.
    * *Caminho A (Com Internet):* O Supabase valida o `lote_id` e atualiza a nuvem. O SQLite marca a flag como `sincronizado = 1`.
    * *Caminho B (Sem Internet):* O erro é capturado silenciosamente. O usuário continua a usar o app. Na próxima requisição, o sistema reenvia as pendências.

---

## 🛠 Tecnologias Utilizadas

* **Frontend Mobile:** Flutter & Dart
* **Gerência de Estado:** Provider (Padrão MVVM - Model-View-ViewModel)
* **Banco de Dados Local:** SQLite (`sqflite` / `sqflite_common_ffi`)
* **Gráficos e UI:** `fl_chart`
* **Backend Híbrido:** Supabase (PostgreSQL)
