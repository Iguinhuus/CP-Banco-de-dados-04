📌 Checkpoint 4 - Banco de Dados
Este projeto faz parte do Checkpoint 4 da disciplina de Banco de Dados, cujo objetivo principal é o desenvolvimento de um modelo estrela em Oracle SQL. O projeto contempla a criação de tabelas dimensionais e fato, procedures para carregamento e tratamento dos dados, além de triggers de auditoria.

---

🛠️ Funcionalidades
✅ Criação de tabelas de dimensão e fato (modelo estrela).
✅ Criação de procedures para inserção de dados com tratamento de exceções.
✅ Validações para garantir a integridade dos dados.
✅ Triggers de auditoria para registrar inserções nas dimensões.
✅ Packages para organização de procedures e execução de cargas.
✅ Execução de scripts de testes para validar as procedures e o modelo.

---

📌 Modelo Estrela
O projeto utiliza o seguinte esquema dimensional:

F_REGISTRO_VENDAS (Tabela Fato)
D_CLIENTES
D_REPRESENTANTE
D_CATALOGO_PRODUTO
D_STATUS_PEDIDO
D_TIPO_PAGAMENTO
D_METODO_PAGAMENTO
D_ENDERECO
D_TEMPO_VENDA

---

🧑‍💻 Participantes
Igor Akira – RM: 554227
Igor Mendes Oviedo – RM: 553434
Thiago Carrilo - RM: 553565

---

🗂️ Diagrama Estrela
![image](https://github.com/user-attachments/assets/825db639-643b-4212-974d-f3f24d345ba7)



---

🧠 Tecnologias Utilizadas
Oracle Database SQL
SQL Developer
PL/SQL
Modelo Estrela (Data Warehouse)
Triggers e Packages

---

▶️ Execução
Para executar o projeto:

Execute o script SQL no Oracle SQL Developer.
Inicie o bloco de SET SERVEROUTPUT ON.
Execute os testes das procedures conforme os exemplos no script.
Use SELECT * FROM AUDITORIA_DIMENSOES para visualizar a auditoria.
Utilize os packages PKG_DIMENSOES e PKG_CARGA_FATO para manipular os dados.
