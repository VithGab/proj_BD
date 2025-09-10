-- Criando tabela de autores

CREATE TABLE autor (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);


-- Criando tabela de livros

CREATE TABLE livro (
    id SERIAL PRIMARY KEY,
    titulo VARCHAR(150) NOT NULL,
    id_autor INT NOT NULL REFERENCES autor(id),
    ano_publicacao INT
);


-- Criando tabela de usuários

CREATE TABLE usuario (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL
);

-- Criando tabela de empréstimos

CREATE TABLE emprestimo (
    id SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL REFERENCES usuario(id),
    id_livro INT NOT NULL REFERENCES livro(id),
    data_emprestimo DATE NOT NULL,
    data_devolucao DATE
);

-- Inserindo autores

INSERT INTO autor (nome) VALUES
('Machado de Assis'),
('J. K. Rowling'),
('George Orwell'),
('Clarice Lispector');

-- Inserindo livros

INSERT INTO livro (titulo, id_autor, ano_publicacao) VALUES
('Dom Casmurro', 1, 1899),
('Harry Potter e a Pedra Filosofal', 2, 1997),
('1984', 3, 1949),
('A Hora da Estrela', 4, 1977),
('Harry Potter e a Câmara Secreta', 2, 1998);

-- Inserindo usuários

INSERT INTO usuario (nome) VALUES
('Ana'),
('Bruno'),
('Carla'),
('Diego');

-- Inserindo empréstimos

INSERT INTO emprestimo (id_usuario, id_livro, data_emprestimo, data_devolucao) VALUES
(1, 1, '2025-08-01', '2025-08-10'),
(2, 2, '2025-08-02', NULL),
(3, 3, '2025-08-05', '2025-08-15'),
(1, 5, '2025-08-07', NULL),
(4, 4, '2025-08-08', NULL);

---Desafios  PROCEDURES
--Questão 1 – Cadastrar novo usuário---------------------------------------------------

create procedure cadastrar_usuario(p_nome varchar)
language plpgsql
as $$
begin
insert into usuario(nome) values(p_nome);
raise notice 'User "%" was successfully registered', p_nome;
end;
$$;
--Testing...
select * from usuario;
call cadastrar_usuario('Gabriel');

--Questão 2 – Registrar novo livro----------------------------------------------------

create procedure cadastrar_livro(p_titulo varchar, p_id_autor int, p_ano_publicacao int)
language plpgsql
as $$
begin
insert into livro(titulo, id_autor, ano_publicacao) 
values(p_titulo, p_id_autor, p_ano_publicacao);
raise notice 'Book "%" was successfully registered', p_titulo;
end;
$$;
--Testing...
select * from livro;
call cadastrar_livro('Água Viva', 4, 1973);

--Questão 3 – Registrar devolução------------------------------------------------------

create procedure registrar_devolucao(p_id_emprestimo int, p_data_devolucao date)
language plpgsql
as $$
begin
update emprestimo set data_devolucao = p_data_devolucao where id = p_id_emprestimo;
end;
$$;
--Testing...
select * from emprestimo;
call registrar_devolucao(2, '2025-09-09');

--Questão 4 – Excluir usuário e seus empréstimos ---------------------------------------

create procedure excluir_usuario(p_id_usuario int)
language plpgsql
as $$
begin
delete from emprestimo where id_usuario = p_id_usuario;
delete from usuario where id = p_id_usuario;
end;
$$;
--Testing...
select * from usuario;
select * from emprestimo;
call excluir_usuario(3);

----------------------------------------------------------------------------------
Desafios  VIEWS
Simples
--VIEW LIVRO_AUTOR.
create view livro_autor
as select l.titulo, a.nome as 
nome_autor
from livro l
join autor a on l.id_autor = a.id;

select * from livro_autor;

--VIEW USUARIO_COM_EMPRESTIMOS
create view usuarios_com_emprestimos as
select u.nome AS 
nome_usuario, l.titulo as titulo_livro
from usuario u
join emprestimo e on u.id = e.id_usuario
join livro l on e.id_livro = l.id;

select * from usuarios_com_emprestimos;

--VIEW EMPRESTIMOS SEM DATA DE DEVOLUÇÃO.
create view emprestimos_abertos
as select * from emprestimo
where data_devolucao is null;

select * from emprestimos_abertos;

Médios
--view historico_emprestimos.
create view historico_emprestimos as
select u.nome as nome_usuario, l.titulo as titulo_livro,
a.nome as nome_autor, e.data_emprestimo
from emprestimo e
join usuario u on e.id_usuario = u.id
join livro l on e.id_livro = l.id
join autor a on l.id_autor = a.id;

select * from historico_emprestimos;

--view qtd_emprestimos_por_usuario.
create view emprestimos_por_usuario as
select u.nome as nome_usuario,
count(e.id_livro) as total_emprestimos
from usuario u
join emprestimo e on u.id = e.id_usuario
group by u.nome;

select * from emprestimos_por_usuario;

--view livros_mais_recentes.
create view livros_mais_recentes as
select l.titulo, a.nome as 
nome_autor, l.ano_publicacao
from livro l
join autor a on l.id_autor = a.id
where l.ano_publicacao > 1950
order by l.ano_publicacao desc;

select * from livros_mais_recentes;

--view usuarios_com_mais_de_um_emprestimo.
create view usuarios_com_mais_de_um_emprestimo as
select u.nome as nome_usuario,
count(e.id_livro) as total_emprestimos
from usuario u
join emprestimo e on u.id = e.id_usuario
group by u.nome
having count(e.id_livro) > 1;

select * from usuarios_com_mais_de_um_emprestimo;

---Functions-------
----autor_do_livro(p_id INT)-------
CREATE FUNCTION autor_do_livro(p_id INT)
RETURNS VARCHAR(100) AS $$
BEGIN
RETURN (SELECT a.nome FROM livro l JOIN autor a ON l.id_autor = a.id
WHERE l.id = p_id);
END;
$$ LANGUAGE plpgsql;
-------livro_emprestado------------------
CREATE FUNCTION livro_emprestado(p_id INT)
RETURNS VARCHAR(200) AS $$
BEGIN
IF EXISTS (SELECT 1 FROM emprestimo WHERE id_livro = p_id AND data_devolucao IS
NULL) THEN
RETURN 'Livro emprestado';
ELSE
RETURN 'Livro disponível';
END IF;
END;
$$ LANGUAGE plpgsql;
------------usuario_com_atraso------
● "Usuário possui livros atrasados" → se tiver empréstimos não
devolvidos há mais de 10 dias.
● "Usuário em dia" → caso contrário.
CREATE OR REPLACE FUNCTION usuario_com_atraso(p_id INT)
RETURNS TEXT AS $$
BEGIN
IF EXISTS (SELECT 1 FROM emprestimo
WHERE id_usuario = p_id
AND data_devolucao IS NULL
AND data_emprestimo < CURRENT_DATE - INTERVAL '10 days') THEN
RETURN 'Usuário possui livros atrasados';
ELSE
RETURN 'Usuário em dia';
END IF;
END;
$$ LANGUAGE plpgsql;
----------------total_gasto_usuario
CREATE FUNCTION total_gasto_usuario(p_id INT)
RETURNS NUMERIC(10,2) AS $$
DECLARE total NUMERIC(10,2);
BEGIN
SELECT SUM(valor) INTO total
FROM emprestimo
WHERE id_usuario = p_id;
IF total IS NULL THEN
RETURN 0;
ELSE
RETURN total;
END IF;
END;
$$ LANGUAGE plpgsql;