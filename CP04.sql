/*Igor Akira RM:554227
Igor Mendes Oviedo RM:553434
*/

SET SERVEROUTPUT ON;

CREATE TABLE tabela_de_pedidos AS
SELECT * FROM pf1788.Pedido;



SELECT * FROM TABELA_DE_PEDIDOS

DESC tabela_de_pedidos;

--------------------------------------------------------------------------------
-- 1. Sequências para geração automática de IDs
CREATE SEQUENCE seq_tempo_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_cliente_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_vendedor_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_endereco_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_produto_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_status_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_pagamento_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_metodo_id START WITH 1 INCREMENT BY 1;

-- 2. Tabelas de Dimensão
CREATE TABLE D_TEMPO_VENDA (
    TEMPO_ID NUMBER DEFAULT seq_tempo_id.NEXTVAL PRIMARY KEY,
    ANO_VENDA NUMBER(4) NOT NULL,
    MES_VENDA NUMBER(2) NOT NULL CHECK (MES_VENDA BETWEEN 1 AND 12),
    DIA_VENDA NUMBER(2) NOT NULL CHECK (DIA_VENDA BETWEEN 1 AND 31),
    DATA_VENDA DATE NOT NULL UNIQUE
);

CREATE TABLE D_CLIENTES (
    CLIENTE_ID NUMBER DEFAULT seq_cliente_id.NEXTVAL PRIMARY KEY,
    NOME VARCHAR2(100) NOT NULL,
    TIPO_CONSUMIDOR VARCHAR2(50) CHECK (TIPO_CONSUMIDOR IN ('Comum', 'Premium', 'VIP'))
);

CREATE TABLE D_REPRESENTANTE (
    VENDEDOR_ID NUMBER DEFAULT seq_vendedor_id.NEXTVAL PRIMARY KEY,
    NOME_COMPLETO VARCHAR2(100) NOT NULL
);

CREATE TABLE D_ENDERECO (
    ENDERECO_ID NUMBER DEFAULT seq_endereco_id.NEXTVAL PRIMARY KEY,
    UF CHAR(2) NOT NULL,
    MUNICIPIO VARCHAR2(50) NOT NULL
);

CREATE TABLE D_CATALOGO_PRODUTO (
    PRODUTO_ID NUMBER DEFAULT seq_produto_id.NEXTVAL PRIMARY KEY,
    DESCRICAO_PRODUTO VARCHAR2(100) NOT NULL,
    TIPO_PRODUTO VARCHAR2(50) CHECK (TIPO_PRODUTO IN ('Eletrônico', 'Vestuário', 'Alimentação'))
);

CREATE TABLE D_STATUS_PEDIDO (
    STATUS_ID NUMBER DEFAULT seq_status_id.NEXTVAL PRIMARY KEY,
    STATUS_DESC VARCHAR2(20) NOT NULL UNIQUE
);

-- 3. Tabelas Auxiliares Normalizadas
CREATE TABLE D_METODO_PAGAMENTO (
    METODO_ID NUMBER DEFAULT seq_metodo_id.NEXTVAL PRIMARY KEY,
    METODO VARCHAR2(30) NOT NULL UNIQUE
);

CREATE TABLE D_TIPO_PAGAMENTO (
    PAGAMENTO_ID NUMBER DEFAULT seq_pagamento_id.NEXTVAL PRIMARY KEY,
    METODO_ID NUMBER REFERENCES D_METODO_PAGAMENTO(METODO_ID),
    FL_PARCELADO CHAR(3) CHECK (FL_PARCELADO IN ('Sim', 'Não'))
);

-- 4. Tabela Fato (Versão Corrigida)
CREATE TABLE F_REGISTRO_VENDAS (
    VENDA_ID NUMBER(12) PRIMARY KEY,
    CLIENTE_ID NUMBER REFERENCES D_CLIENTES(CLIENTE_ID),
    VENDEDOR_ID NUMBER REFERENCES D_REPRESENTANTE(VENDEDOR_ID),
    STATUS_ID NUMBER REFERENCES D_STATUS_PEDIDO(STATUS_ID),
    PAGAMENTO_ID NUMBER REFERENCES D_TIPO_PAGAMENTO(PAGAMENTO_ID),
    PRODUTO_ID NUMBER REFERENCES D_CATALOGO_PRODUTO(PRODUTO_ID),
    ENDERECO_ID NUMBER REFERENCES D_ENDERECO(ENDERECO_ID),
    TEMPO_ID NUMBER REFERENCES D_TEMPO_VENDA(TEMPO_ID),
    QUANTIDADE NUMBER(10) CHECK (QUANTIDADE > 0),
    VALOR_TOTAL NUMBER(12,2) CHECK (VALOR_TOTAL >= 0),
    DESCONTO NUMBER(12,2),
    -- Restrição de tabela para validar DESCONTO
    CONSTRAINT CK_DESCONTO_VALIDO CHECK (DESCONTO BETWEEN 0 AND VALOR_TOTAL)
);

-- Consultas de teste
SELECT * FROM D_CLIENTES;
SELECT * FROM D_REPRESENTANTE;
SELECT * FROM D_CATALOGO_PRODUTO;
SELECT * FROM D_STATUS_PEDIDO;
SELECT * FROM D_TIPO_PAGAMENTO;
SELECT * FROM F_REGISTRO_VENDAS;

--------------------------------------------------------------------------------
--------------------------------- PROCEDURES -----------------------------------
--------------------------------------------------------------------------------

--Procedure para D_TEMPO_VENDA

CREATE OR REPLACE PROCEDURE INSERIR_D_TEMPO_VENDA (
    p_data_str IN VARCHAR2
) AS
    v_data DATE;
BEGIN
    -- Validação da data
    BEGIN
        v_data := TO_DATE(p_data_str, 'DD/MM/YYYY');
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20001, 'Formato de data inválido. Use DD/MM/YYYY.');
    END;

    -- Inserção com validação de mês/dia
    INSERT INTO D_TEMPO_VENDA (ANO_VENDA, MES_VENDA, DIA_VENDA, DATA_VENDA)
    VALUES (
        EXTRACT(YEAR FROM v_data),
        EXTRACT(MONTH FROM v_data),
        EXTRACT(DAY FROM v_data),
        v_data
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erro ao inserir tempo: ' || SQLERRM);
END;
/

--Procedure para D_CLIENTES

CREATE OR REPLACE PROCEDURE INSERIR_D_CLIENTES (
    p_nome IN VARCHAR2,
    p_tipo_consumidor IN VARCHAR2
) AS
BEGIN
    -- Validação de nome e tipo
    IF p_nome IS NULL OR LENGTH(TRIM(p_nome)) < 2 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Nome do cliente é obrigatório (mín. 2 caracteres).');
    END IF;

    IF p_tipo_consumidor NOT IN ('Comum', 'Premium', 'VIP') THEN
        RAISE_APPLICATION_ERROR(-20004, 'Tipo de consumidor inválido. Valores: Comum, Premium, VIP.');
    END IF;

    -- Inserção
    INSERT INTO D_CLIENTES (NOME, TIPO_CONSUMIDOR)
    VALUES (p_nome, p_tipo_consumidor);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20005, 'Erro ao inserir cliente: ' || SQLERRM);
END;
/

--Procedure para D_REPRESENTANTE

CREATE OR REPLACE PROCEDURE INSERIR_D_REPRESENTANTE (
    p_nome_completo IN VARCHAR2
) AS
BEGIN
    -- Validação do nome
    IF p_nome_completo IS NULL OR LENGTH(TRIM(p_nome_completo)) < 3 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Nome do representante é obrigatório (mín. 3 caracteres).');
    END IF;

    -- Inserção
    INSERT INTO D_REPRESENTANTE (NOME_COMPLETO)
    VALUES (p_nome_completo);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20007, 'Erro ao inserir representante: ' || SQLERRM);
END;
/

--Procedure para D_ENDERECO

CREATE OR REPLACE PROCEDURE INSERIR_D_ENDERECO (
    p_uf IN CHAR,
    p_municipio IN VARCHAR2
) AS
BEGIN
    -- Validação de UF e município
    IF LENGTH(p_uf) != 2 THEN
        RAISE_APPLICATION_ERROR(-20008, 'UF deve ter exatamente 2 caracteres.');
    END IF;

    IF p_municipio IS NULL OR TRIM(p_municipio) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20009, 'Município é obrigatório.');
    END IF;

    -- Inserção
    INSERT INTO D_ENDERECO (UF, MUNICIPIO)
    VALUES (p_uf, p_municipio);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'Erro ao inserir endereço: ' || SQLERRM);
END;
/

--Procedure para D_CATALOGO_PRODUTO

CREATE OR REPLACE PROCEDURE INSERIR_D_CATALOGO_PRODUTO (
    p_descricao_produto IN VARCHAR2,
    p_tipo_produto IN VARCHAR2
) AS
BEGIN
    -- Validação de descrição e tipo
    IF p_descricao_produto IS NULL OR TRIM(p_descricao_produto) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20011, 'Descrição do produto é obrigatória.');
    END IF;

    IF p_tipo_produto NOT IN ('Eletrônico', 'Vestuário', 'Alimentação') THEN
        RAISE_APPLICATION_ERROR(-20012, 'Tipo de produto inválido. Valores: Eletrônico, Vestuário, Alimentação.');
    END IF;

    -- Inserção
    INSERT INTO D_CATALOGO_PRODUTO (DESCRICAO_PRODUTO, TIPO_PRODUTO)
    VALUES (p_descricao_produto, p_tipo_produto);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20013, 'Erro ao inserir produto: ' || SQLERRM);
END;
/

--Procedure para D_STATUS_PEDIDO

CREATE OR REPLACE PROCEDURE INSERIR_D_STATUS_PEDIDO (
    p_status_desc IN VARCHAR2
) AS
BEGIN
    -- Validação de descrição
    IF p_status_desc IS NULL THEN
        RAISE_APPLICATION_ERROR(-20014, 'Descrição do status é obrigatória.');
    END IF;

    -- Inserção
    INSERT INTO D_STATUS_PEDIDO (STATUS_DESC)
    VALUES (p_status_desc);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20015, 'Status já existe.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20016, 'Erro ao inserir status: ' || SQLERRM);
END;
/

--Procedure para D_METODO_PAGAMENTO

CREATE OR REPLACE PROCEDURE INSERIR_D_METODO_PAGAMENTO (
    p_metodo IN VARCHAR2
) AS
BEGIN
    -- Validação de método
    IF p_metodo IS NULL THEN
        RAISE_APPLICATION_ERROR(-20017, 'Método de pagamento é obrigatório.');
    END IF;

    -- Inserção
    INSERT INTO D_METODO_PAGAMENTO (METODO)
    VALUES (p_metodo);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20018, 'Método de pagamento já existe.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20019, 'Erro ao inserir método: ' || SQLERRM);
END;
/

--Procedure para D_TIPO_PAGAMENTO

CREATE OR REPLACE PROCEDURE INSERIR_D_TIPO_PAGAMENTO (
    p_metodo_id IN NUMBER,
    p_fl_parcelado IN CHAR
) AS
    v_count NUMBER;
BEGIN
    -- Validação de método existente
    SELECT COUNT(*) INTO v_count FROM D_METODO_PAGAMENTO WHERE METODO_ID = p_metodo_id;
    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Método de pagamento não encontrado.');
    END IF;

    -- Validação de parcelamento
    IF p_fl_parcelado NOT IN ('Sim', 'Não') THEN
        RAISE_APPLICATION_ERROR(-20021, 'FL_PARCELADO deve ser "Sim" ou "Não".');
    END IF;

    -- Inserção
    INSERT INTO D_TIPO_PAGAMENTO (METODO_ID, FL_PARCELADO)
    VALUES (p_metodo_id, p_fl_parcelado);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20022, 'Erro ao inserir tipo de pagamento: ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
--------------------------- TESTE DAS PROCEDURES -------------------------------
--------------------------------------------------------------------------------

--------------------- D_TEMPO_VENDA ----------------------
-- Teste 1: Data válida
BEGIN
    INSERIR_D_TEMPO_VENDA('15/10/2023');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Data inserida.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Data válida): ' || SQLERRM);
END;
/

-- Teste 2: Data inválida (formato incorreto)
BEGIN
    INSERIR_D_TEMPO_VENDA('2023-10-15');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (Data inválida): ' || SQLERRM);
END;
/

----------------------- D_CLIENTES ------------------------
-- Teste 1: Cliente válido
BEGIN
    INSERIR_D_CLIENTES('Maria Oliveira', 'VIP');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Cliente inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Cliente válido): ' || SQLERRM);
END;
/

-- Teste 2: Tipo de consumidor inválido
BEGIN
    INSERIR_D_CLIENTES('Pedro Santos', 'Gold');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (Tipo inválido): ' || SQLERRM);
END;
/

--------------------- D_REPRESENTANTE ---------------------
-- Teste 1: Nome válido
BEGIN
    INSERIR_D_REPRESENTANTE('Ana Paula Costa');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Representante inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Nome válido): ' || SQLERRM);
END;
/

-- Teste 2: Nome curto demais
BEGIN
    INSERIR_D_REPRESENTANTE('Li');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (Nome inválido): ' || SQLERRM);
END;
/

---------------------- D_ENDERECO -------------------------
-- Teste 1: UF e município válidos
BEGIN
    INSERIR_D_ENDERECO('SP', 'São Paulo');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Endereço inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Endereço válido): ' || SQLERRM);
END;
/

-- Teste 2: UF inválida
BEGIN
    INSERIR_D_ENDERECO('S', 'Campinas');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (UF inválida): ' || SQLERRM);
END;
/

------------------ D_CATALOGO_PRODUTO ---------------------
-- Teste 1: Produto válido
BEGIN
    INSERIR_D_CATALOGO_PRODUTO('Smartphone XYZ', 'Eletrônico');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Produto inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Produto válido): ' || SQLERRM);
END;
/

-- Teste 2: Tipo de produto inválido
BEGIN
    INSERIR_D_CATALOGO_PRODUTO('Camiseta Básica', 'Têxtil');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (Tipo inválido): ' || SQLERRM);
END;
/

-------------------- D_STATUS_PEDIDO ----------------------
-- Teste 1: Status válido
BEGIN
    INSERIR_D_STATUS_PEDIDO('Em transporte');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Status inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Status válido): ' || SQLERRM);
END;
/

-- Teste 2: Status duplicado (executar duas vezes)
BEGIN
    INSERIR_D_STATUS_PEDIDO('Finalizado');
    INSERIR_D_STATUS_PEDIDO('Finalizado');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (Status duplicado): ' || SQLERRM);
END;
/

---------------- D_METODO_PAGAMENTO -----------------------
-- Teste 1: Método válido
BEGIN
    INSERIR_D_METODO_PAGAMENTO('PIX');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Método inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Método válido): ' || SQLERRM);
END;
/

---------------- D_TIPO_PAGAMENTO -------------------------
-- Pré-requisito: Inserir método de pagamento
BEGIN
    INSERIR_D_METODO_PAGAMENTO('Cartão de Crédito');
END;
/

-- Teste 1: Tipo válido
BEGIN
    INSERIR_D_TIPO_PAGAMENTO(1, 'Sim');
    DBMS_OUTPUT.PUT_LINE('SUCESSO: Tipo de pagamento inserido.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('FALHA (Tipo válido): ' || SQLERRM);
END;
/

-- Teste 2: Método inexistente
BEGIN
    INSERIR_D_TIPO_PAGAMENTO(999, 'Não');
    DBMS_OUTPUT.PUT_LINE('FALHA: Este teste deveria falhar.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('SUCESSO (Método inválido): ' || SQLERRM);
END;
/

--------------------------------------------------------------------------------
---------------------------- VERIFICAÇÃO FINAL ---------------------------------
--------------------------------------------------------------------------------
-- Consultar dados inseridos
SELECT 'Clientes' AS Tabela, COUNT(*) AS Registros FROM D_CLIENTES
UNION ALL
SELECT 'Representantes', COUNT(*) FROM D_REPRESENTANTE
UNION ALL
SELECT 'Produtos', COUNT(*) FROM D_CATALOGO_PRODUTO
UNION ALL
SELECT 'Status', COUNT(*) FROM D_STATUS_PEDIDO;

--------------------------------------------------------------------------------
---------------------------- CARREGAMENTO DE DADOS -----------------------------
--------------------------------------------------------------------------------

-- 1. Carregar Dimensão CLIENTES
INSERT INTO D_CLIENTES (NOME, TIPO_CONSUMIDOR)
SELECT DISTINCT
    'Cliente ' || COD_CLIENTE,  -- Substituir por nome real se disponível
    'Comum'                     -- Valor padrão
FROM tabela_de_pedidos
WHERE COD_CLIENTE IS NOT NULL
AND NOT EXISTS (
    SELECT 1 
    FROM D_CLIENTES 
    WHERE NOME = 'Cliente ' || COD_CLIENTE
);

-- 2. Carregar Dimensão REPRESENTANTE
INSERT INTO D_REPRESENTANTE (NOME_COMPLETO)
SELECT DISTINCT
    'Vendedor ' || COD_VENDEDOR  -- Substituir por nome real se disponível
FROM tabela_de_pedidos
WHERE COD_VENDEDOR IS NOT NULL
AND NOT EXISTS (
    SELECT 1 
    FROM D_REPRESENTANTE 
    WHERE NOME_COMPLETO = 'Vendedor ' || COD_VENDEDOR
);

-- 3. Carregar Dimensão STATUS
INSERT INTO D_STATUS_PEDIDO (STATUS_DESC)
SELECT DISTINCT STATUS
FROM tabela_de_pedidos
WHERE STATUS IS NOT NULL
AND NOT EXISTS (
    SELECT 1 
    FROM D_STATUS_PEDIDO 
    WHERE STATUS_DESC = STATUS
);

-- 4. Carregar Dimensão PAGAMENTO
-- Primeiro métodos de pagamento
INSERT INTO D_METODO_PAGAMENTO (METODO)
SELECT DISTINCT 'Cartão de Crédito' 
FROM dual
WHERE NOT EXISTS (
    SELECT 1 
    FROM D_METODO_PAGAMENTO 
    WHERE METODO = 'Cartão de Crédito'
);

-- Depois tipos de pagamento
INSERT INTO D_TIPO_PAGAMENTO (METODO_ID, FL_PARCELADO)
SELECT 
    m.METODO_ID,
    'Sim'  -- Valor padrão
FROM D_METODO_PAGAMENTO m
WHERE m.METODO = 'Cartão de Crédito'
AND NOT EXISTS (
    SELECT 1 
    FROM D_TIPO_PAGAMENTO 
    WHERE METODO_ID = m.METODO_ID
);

-- 5. Carregar FATO
INSERT INTO F_REGISTRO_VENDAS (
    VENDA_ID,
    CLIENTE_ID,
    VENDEDOR_ID,
    STATUS_ID,
    PAGAMENTO_ID,
    PRODUTO_ID,
    ENDERECO_ID,
    TEMPO_ID,
    QUANTIDADE,
    VALOR_TOTAL,
    DESCONTO
)
SELECT
    p.COD_PEDIDO,
    c.CLIENTE_ID,
    v.VENDEDOR_ID,
    s.STATUS_ID,
    t.PAGAMENTO_ID,
    (SELECT PRODUTO_ID FROM D_CATALOGO_PRODUTO WHERE DESCRICAO_PRODUTO = 'Produto Genérico'),
    (SELECT ENDERECO_ID FROM D_ENDERECO WHERE UF = 'SP' AND MUNICIPIO = 'São Paulo'),
    tm.TEMPO_ID,
    1,
    p.VAL_TOTAL_PEDIDO,
    p.VAL_DESCONTO
FROM tabela_de_pedidos p
JOIN D_CLIENTES c ON c.NOME = 'Cliente ' || TO_CHAR(p.COD_CLIENTE)
JOIN D_REPRESENTANTE v ON v.NOME_COMPLETO = 'Vendedor ' || TO_CHAR(p.COD_VENDEDOR)
JOIN D_STATUS_PEDIDO s ON UPPER(s.STATUS_DESC) = UPPER(TRIM(p.STATUS))
JOIN D_TIPO_PAGAMENTO t ON t.PAGAMENTO_ID = 1
JOIN D_TEMPO_VENDA tm ON TRUNC(tm.DATA_VENDA) = TRUNC(p.DAT_PEDIDO)
WHERE p.VAL_DESCONTO BETWEEN 0 AND p.VAL_TOTAL_PEDIDO;

COMMIT;


SELECT COUNT(*) FROM F_REGISTRO_VENDAS;

--------------------------------------------------------------------------------
------------------- EMPACOTAMENTO DAS PRCEDURES E OBJETOS -----------------------
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_DIMENSOES AS
    PROCEDURE INSERIR_D_TEMPO_VENDA(p_data_str IN VARCHAR2);
    PROCEDURE INSERIR_D_CLIENTES(p_nome IN VARCHAR2, p_tipo_consumidor IN VARCHAR2);
    PROCEDURE INSERIR_D_REPRESENTANTE(p_nome_completo IN VARCHAR2);
    PROCEDURE INSERIR_D_ENDERECO(p_uf IN CHAR, p_municipio IN VARCHAR2);
    PROCEDURE INSERIR_D_CATALOGO_PRODUTO(p_descricao_produto IN VARCHAR2, p_tipo_produto IN VARCHAR2);
    PROCEDURE INSERIR_D_STATUS_PEDIDO(p_status_desc IN VARCHAR2);
    PROCEDURE INSERIR_D_METODO_PAGAMENTO(p_metodo IN VARCHAR2);
    PROCEDURE INSERIR_D_TIPO_PAGAMENTO(p_metodo_id IN NUMBER, p_fl_parcelado IN CHAR);
END PKG_DIMENSOES;
/

CREATE OR REPLACE PACKAGE BODY PKG_DIMENSOES AS

    PROCEDURE INSERIR_D_TEMPO_VENDA(p_data_str IN VARCHAR2) IS
        v_data DATE;
    BEGIN
        BEGIN
            v_data := TO_DATE(p_data_str, 'DD/MM/YYYY');
        EXCEPTION
            WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR(-20001, 'Formato de data inválido.');
        END;

        INSERT INTO D_TEMPO_VENDA (ANO_VENDA, MES_VENDA, DIA_VENDA, DATA_VENDA)
        VALUES (
            EXTRACT(YEAR FROM v_data),
            EXTRACT(MONTH FROM v_data),
            EXTRACT(DAY FROM v_data),
            v_data
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Erro ao inserir tempo: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_CLIENTES(p_nome IN VARCHAR2, p_tipo_consumidor IN VARCHAR2) IS
    BEGIN
        IF p_nome IS NULL OR LENGTH(TRIM(p_nome)) < 2 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Nome do cliente é obrigatório (mín. 2 caracteres).');
        END IF;

        IF p_tipo_consumidor NOT IN ('Comum', 'Premium', 'VIP') THEN
            RAISE_APPLICATION_ERROR(-20004, 'Tipo de consumidor inválido.');
        END IF;

        INSERT INTO D_CLIENTES (NOME, TIPO_CONSUMIDOR)
        VALUES (p_nome, p_tipo_consumidor);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20005, 'Erro ao inserir cliente: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_REPRESENTANTE(p_nome_completo IN VARCHAR2) IS
    BEGIN
        IF p_nome_completo IS NULL OR LENGTH(TRIM(p_nome_completo)) < 3 THEN
            RAISE_APPLICATION_ERROR(-20006, 'Nome do representante é obrigatório (mín. 3 caracteres).');
        END IF;

        INSERT INTO D_REPRESENTANTE (NOME_COMPLETO)
        VALUES (p_nome_completo);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20007, 'Erro ao inserir representante: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_ENDERECO(p_uf IN CHAR, p_municipio IN VARCHAR2) IS
    BEGIN
        IF LENGTH(p_uf) != 2 THEN
            RAISE_APPLICATION_ERROR(-20008, 'UF deve ter exatamente 2 caracteres.');
        END IF;

        IF p_municipio IS NULL OR TRIM(p_municipio) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20009, 'Município é obrigatório.');
        END IF;

        INSERT INTO D_ENDERECO (UF, MUNICIPIO)
        VALUES (p_uf, p_municipio);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20010, 'Erro ao inserir endereço: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_CATALOGO_PRODUTO(p_descricao_produto IN VARCHAR2, p_tipo_produto IN VARCHAR2) IS
    BEGIN
        IF p_descricao_produto IS NULL OR TRIM(p_descricao_produto) IS NULL THEN
            RAISE_APPLICATION_ERROR(-20011, 'Descrição do produto é obrigatória.');
        END IF;

        IF p_tipo_produto NOT IN ('Eletrônico', 'Vestuário', 'Alimentação') THEN
            RAISE_APPLICATION_ERROR(-20012, 'Tipo de produto inválido.');
        END IF;

        INSERT INTO D_CATALOGO_PRODUTO (DESCRICAO_PRODUTO, TIPO_PRODUTO)
        VALUES (p_descricao_produto, p_tipo_produto);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20013, 'Erro ao inserir produto: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_STATUS_PEDIDO(p_status_desc IN VARCHAR2) IS
    BEGIN
        IF p_status_desc IS NULL THEN
            RAISE_APPLICATION_ERROR(-20014, 'Descrição do status é obrigatória.');
        END IF;

        INSERT INTO D_STATUS_PEDIDO (STATUS_DESC)
        VALUES (p_status_desc);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20015, 'Status já existe.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20016, 'Erro ao inserir status: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_METODO_PAGAMENTO(p_metodo IN VARCHAR2) IS
    BEGIN
        IF p_metodo IS NULL THEN
            RAISE_APPLICATION_ERROR(-20017, 'Método de pagamento é obrigatório.');
        END IF;

        INSERT INTO D_METODO_PAGAMENTO (METODO)
        VALUES (p_metodo);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20018, 'Método de pagamento já existe.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20019, 'Erro ao inserir método: ' || SQLERRM);
    END;

    PROCEDURE INSERIR_D_TIPO_PAGAMENTO(p_metodo_id IN NUMBER, p_fl_parcelado IN CHAR) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM D_METODO_PAGAMENTO WHERE METODO_ID = p_metodo_id;
        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20020, 'Método de pagamento não encontrado.');
        END IF;

        IF p_fl_parcelado NOT IN ('Sim', 'Não') THEN
            RAISE_APPLICATION_ERROR(-20021, 'FL_PARCELADO deve ser "Sim" ou "Não".');
        END IF;

        INSERT INTO D_TIPO_PAGAMENTO (METODO_ID, FL_PARCELADO)
        VALUES (p_metodo_id, p_fl_parcelado);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20022, 'Erro ao inserir tipo de pagamento: ' || SQLERRM);
    END;

END PKG_DIMENSOES;
/


CREATE OR REPLACE PACKAGE PKG_CARGA_FATO AS
    PROCEDURE CARGA_REGISTROS_VENDAS;
END PKG_CARGA_FATO;
/

CREATE OR REPLACE PACKAGE BODY PKG_CARGA_FATO AS

    PROCEDURE CARGA_REGISTROS_VENDAS IS
    BEGIN
        INSERT INTO F_REGISTRO_VENDAS (
            VENDA_ID,
            CLIENTE_ID,
            VENDEDOR_ID,
            STATUS_ID,
            PAGAMENTO_ID,
            PRODUTO_ID,
            ENDERECO_ID,
            TEMPO_ID,
            QUANTIDADE,
            VALOR_TOTAL,
            DESCONTO
        )
        SELECT
            p.COD_PEDIDO,
            c.CLIENTE_ID,
            v.VENDEDOR_ID,
            s.STATUS_ID,
            t.PAGAMENTO_ID,
            prod.PRODUTO_ID,
            e.ENDERECO_ID,
            tm.TEMPO_ID,
            1,
            p.VAL_TOTAL_PEDIDO,
            p.VAL_DESCONTO
        FROM tabela_de_pedidos p
        JOIN D_CLIENTES c ON c.NOME = 'Cliente ' || TO_CHAR(p.COD_CLIENTE)
        JOIN D_REPRESENTANTE v ON v.NOME_COMPLETO = 'Vendedor ' || TO_CHAR(p.COD_VENDEDOR)
        JOIN D_STATUS_PEDIDO s ON UPPER(s.STATUS_DESC) = UPPER(TRIM(p.STATUS))
        JOIN D_TIPO_PAGAMENTO t ON t.PAGAMENTO_ID = 1
        JOIN D_TEMPO_VENDA tm ON TRUNC(tm.DATA_VENDA) = TRUNC(p.DAT_PEDIDO)
        JOIN D_CATALOGO_PRODUTO prod ON prod.DESCRICAO_PRODUTO = 'Produto Genérico'
        JOIN D_ENDERECO e ON e.UF = 'SP' AND e.MUNICIPIO = 'São Paulo'
        WHERE p.VAL_DESCONTO BETWEEN 0 AND p.VAL_TOTAL_PEDIDO
        AND NOT EXISTS (
            SELECT 1 FROM F_REGISTRO_VENDAS f WHERE f.VENDA_ID = p.COD_PEDIDO
        );

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20500, 'Erro na carga da F_REGISTRO_VENDAS: ' || SQLERRM);
    END;

END PKG_CARGA_FATO;
/

--------------------------------------------------------------------------------
--------------------------- EXECUÇÃO DAS PROCEDURES ----------------------------
--------------------------------------------------------------------------------

-- Exemplo de chamadas individuais (para testes ou scripts)
BEGIN
    PKG_DIMENSOES.INSERIR_D_TEMPO_VENDA('15/10/2023');
    PKG_DIMENSOES.INSERIR_D_CLIENTES('Cliente 999', 'Comum');
    PKG_DIMENSOES.INSERIR_D_REPRESENTANTE('Vendedor 999');
    PKG_DIMENSOES.INSERIR_D_ENDERECO('SP', 'São Paulo');
    PKG_DIMENSOES.INSERIR_D_CATALOGO_PRODUTO('Produto Genérico', 'Eletrônico');
    PKG_DIMENSOES.INSERIR_D_STATUS_PEDIDO('Finalizado');
    PKG_DIMENSOES.INSERIR_D_TIPO_PAGAMENTO(1, 'Sim');
END;
/

BEGIN
    PKG_CARGA_FATO.CARGA_REGISTROS_VENDAS;
END;
/


SELECT COUNT(*) FROM F_REGISTRO_VENDAS;


--------------------------------------------------------------------------------
--------------------------- TRIGGER DE AUDITORIA -------------------------------
--------------------------------------------------------------------------------

CREATE TABLE AUDITORIA_DIMENSOES (
    ID_AUDITORIA     NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    NOME_TABELA      VARCHAR2(50),
    ACAO             VARCHAR2(10),
    USUARIO_SISTEMA  VARCHAR2(30),
    DATA_OPERACAO    TIMESTAMP DEFAULT SYSTIMESTAMP
);


CREATE OR REPLACE TRIGGER TRG_AUD_D_CLIENTES
AFTER INSERT ON D_CLIENTES
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_CLIENTES',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_D_REPRESENTANTE
AFTER INSERT ON D_REPRESENTANTE
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_REPRESENTANTE',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_D_ENDERECO
AFTER INSERT ON D_ENDERECO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_ENDERECO',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_D_CATALOGO_PRODUTO
AFTER INSERT ON D_CATALOGO_PRODUTO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_CATALOGO_PRODUTO',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_D_STATUS_PEDIDO
AFTER INSERT ON D_STATUS_PEDIDO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_STATUS_PEDIDO',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_D_METODO_PAGAMENTO
AFTER INSERT ON D_METODO_PAGAMENTO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_METODO_PAGAMENTO',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_D_TIPO_PAGAMENTO
AFTER INSERT ON D_TIPO_PAGAMENTO
FOR EACH ROW
BEGIN
    INSERT INTO AUDITORIA_DIMENSOES (
        NOME_TABELA,
        ACAO,
        USUARIO_SISTEMA,
        DATA_OPERACAO
    ) VALUES (
        'D_TIPO_PAGAMENTO',
        'INSERT',
        USER,
        SYSTIMESTAMP
    );
END;
/

--------------------------------------------------------------------------------
------------------------------ TESTE TRIGGER -----------------------------------
--------------------------------------------------------------------------------

SELECT * FROM AUDITORIA_DIMENSOES ORDER BY DATA_OPERACAO DESC;

BEGIN
    PKG_DIMENSOES.INSERIR_D_CLIENTES('Cliente Teste', 'Comum');
END;
/


