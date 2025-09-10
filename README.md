
###Projeto de Gerenciamento de Biblioteca em PostgreSQL
Minha abordagem foi estruturar o projeto em partes lógicas. Primeiro, criei as tabelas necessárias para o sistema. Depois, adicionei alguns dados de teste para simular um ambiente real. Por fim, desenvolvi as rotinas e visões que automatizam e simplificam as operações da biblioteca.

---
### 1. Procedures (Procedimentos)

Para as procedures, eu pensei em tarefas que um bibliotecário faria no dia a dia. A ideia era criar rotinas que executam uma série de comandos SQL em uma única chamada.

* **`cadastrar_usuario`**: Criei esta procedure para simplificar o registro de novos usuários. Ela recebe apenas o nome do usuário como parâmetro e o insere na tabela `usuario`. Para dar um feedback visual, incluí um `raise notice` que confirma o cadastro.
* **`cadastrar_livro`**: Similar ao cadastro de usuário, esta procedure permite adicionar um novo livro ao acervo. Ela recebe o título, o ID do autor e o ano de publicação. Eu usei um `INSERT INTO` para colocar os dados na tabela `livro` e adicionei um `raise notice` para confirmar a operação.
* **`registrar_devolucao`**: Esta é uma procedure fundamental para o controle do acervo. Ela atualiza a `data_devolucao` de um empréstimo específico, identificando-o pelo seu ID. Usei um comando `UPDATE` com uma cláusula `WHERE` para garantir que apenas o registro correto fosse modificado.
* **`excluir_usuario`**: Para lidar com a exclusão de usuários, precisei pensar na regra de **integridade referencial**. Como um usuário pode ter empréstimos registrados, eu não poderia simplesmente apagá-lo da tabela `usuario` sem antes remover seus empréstimos. Por isso, a procedure executa um `DELETE` na tabela `emprestimo` primeiro, e depois um `DELETE` na tabela `usuario`.

---

### 2. Views (Visões)

As views me ajudaram a simplificar consultas complexas e a criar "tabelas virtuais" que combinam dados de diferentes tabelas. Isso me permitiu ter acesso a informações agregadas de forma fácil e rápida.

* **Views Simples**:
    * **`livro_autor`**: Eu juntei as tabelas `livro` e `autor` com um `JOIN` para que eu pudesse ver o título de cada livro ao lado do nome do seu autor.
    * **`usuarios_com_emprestimos`**: Usei três `JOINs` para conectar as tabelas `usuario`, `emprestimo` e `livro` e exibir o nome do usuário e o título do livro que ele pegou emprestado.
    * **`emprestimos_abertos`**: Esta foi a mais simples. Criei uma view que filtra a tabela `emprestimo`, mostrando apenas os registros onde a coluna `data_devolucao` está **nula** (`IS NULL`).

* **Views Complexas**:
    * **`historico_emprestimos`**: Combinei as quatro tabelas do meu sistema (`emprestimo`, `usuario`, `livro`, `autor`) para ter uma visão completa de todos os empréstimos, com detalhes sobre quem pegou o livro, qual livro era e quem o escreveu.
    * **`emprestimos_por_usuario`**: Para ver o volume de empréstimos por usuário, usei um `COUNT` e um `GROUP BY` no nome do usuário.
    * **`livros_mais_recentes`**: Filtrei os livros publicados após 1950 usando a cláusula `WHERE` e ordenei-os por ano de publicação (`ORDER BY`) de forma decrescente para ter a lista dos mais novos primeiro.
    * **`usuarios_com_mais_de_um_emprestimo`**: Usei a mesma lógica de contagem de empréstimos, mas adicionei a cláusula `HAVING` para filtrar apenas os usuários que pegaram mais de um livro.

---

### 3. Functions (Funções)

As funções foram essenciais para criar lógicas de negócio reutilizáveis. Diferente das procedures, as funções sempre retornam um valor.

* **`autor_do_livro(p_id INT)`**: Esta função é bem direta. Recebe o ID de um livro e, através de um `JOIN`, retorna o nome do autor correspondente.
* **`livro_emprestado(p_id INT)`**: Usei a estrutura de controle `IF EXISTS` para verificar se existe algum empréstimo para um determinado livro (`id_livro = p_id`) onde a devolução ainda não foi feita (`data_devolucao IS NULL`). A função retorna uma string ("Livro emprestado" ou "Livro disponível") com base nessa verificação.
* **`usuario_com_atraso(p_id INT)`**: Para esta função, eu precisei de uma lógica mais avançada. Verifico se existe um empréstimo para o usuário (`id_usuario = p_id`) que ainda não foi devolvido e cuja data de empréstimo é mais antiga do que 10 dias atrás. A comparação `data_emprestimo < CURRENT_DATE - INTERVAL '10 days'` me permitiu identificar os atrasos.
* **`total_gasto_usuario(p_id INT)`**: Embora a tabela de `emprestimo` não tenha uma coluna de valor, a lógica desta função seria somar os valores de todos os empréstimos de um usuário. Eu usei a estrutura `DECLARE` para a variável `total` e um `IF total IS NULL` para garantir que a função retorne `0` se o usuário não tiver gastos.
