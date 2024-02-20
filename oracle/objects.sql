alter session set container = GAY_PDB;


CREATE SEQUENCE ServiceIDSequence
START WITH 1
INCREMENT BY 1
NOMINVALUE
NOMAXVALUE
NOCACHE;

SELECT ServiceIDSequence.NEXTVAL FROM SERVICES;


CREATE SEQUENCE EmployeeIDSequence
START WITH 1
INCREMENT BY 1
NOMINVALUE
NOMAXVALUE
NOCACHE;

-- Индексы
--
--CREATE INDEX IX_Registration_ClientID ON REGISTRATION(clientID);
--CREATE INDEX IX_Employees_ServiceID ON EMPLOYEES(serviceID);
--CREATE INDEX IX_Reviews_EmployeeID ON REVIEWS(employeeID);
--
--DROP INDEX IX_Registration_ClientID;
--DROP INDEX IX_Employees_ServiceID;
--DROP INDEX IX_Reviews_EmployeeID;


-- Представления

CREATE OR REPLACE VIEW MyServiceView AS
SELECT serviceID, name, description, price
FROM SERVICES;

SELECT * FROM MyServiceView;

CREATE OR REPLACE VIEW MyEmployeeView AS
SELECT employeeID, name, surname, positions, serviceID, phone, email
FROM EMPLOYEES;


-----------------------------------------

--функции
 CREATE OR REPLACE FUNCTION IsEmailValid(p_Email CLIENTS.email%type) RETURN BOOLEAN
IS
    v_Pattern VARCHAR2(100) := '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
BEGIN
    RETURN REGEXP_LIKE(p_Email, v_Pattern);
END;
----------------------------

 CREATE OR REPLACE FUNCTION IsEmployeeExists(p_employeeID EMPLOYEES.employeeID%type) RETURN BOOLEAN
IS
    v_Count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_Count FROM EMPLOYEES WHERE employeeID = p_employeeID;
    RETURN v_Count > 0;
END;
-------------------------------
 CREATE OR REPLACE FUNCTION IsServiceExists(p_serviceID SERVICES.serviceID%type) RETURN BOOLEAN
IS
    v_Count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_Count FROM SERVICES WHERE serviceID = p_serviceID;
    RETURN v_Count > 0;
END;

----------------------------------------------
--процедуры
CREATE OR REPLACE PROCEDURE AddService(   
    p_name IN SERVICES.name%TYPE,    
    p_description IN SERVICES.description%TYPE,    
    p_price IN SERVICES.price%TYPE
)
IS
BEGIN
    IF
        p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 or
        p_description IS NULL or length(trim(p_description)) = 0 or
        p_price is null THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Поле не может быть пустым.');
        RETURN;
    END if;

     IF NOT REGEXP_LIKE(p_name, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Название услуги должно содержать только буквы.');
        RETURN;
    END IF;

    IF NOT REGEXP_LIKE(p_description, '^[[:alpha:],.\- ]+$') THEN
    sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Отзыв должен содержать только буквы, запятые, точки, дефисы и пробелы.');
    RETURN;
END IF;

    -- Проверка на корректность входящих данных
   BEGIN
        IF p_price < 0 THEN
            sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Цена не может быть отрицательной.');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Цена должна быть числом.');
            RETURN;
    END;

    INSERT INTO SERVICES (name, description, price)
    VALUES (TRIM(p_name), TRIM(p_description), p_price);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Услуга добавлена успешно.');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('Услуга с таким id уже существует.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Ошибка добавления услуги: ' || SQLERRM);
        RAISE;
END;

------------------------------------
CREATE OR REPLACE PROCEDURE UpdateService(
    p_serviceID IN SERVICES.serviceID%TYPE,
    p_name IN SERVICES.name%TYPE,
    p_description IN SERVICES.description%TYPE,
    p_price IN SERVICES.price%TYPE
)
IS
BEGIN
    IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Название услуги не может быть пустым.');
        RETURN;
    END IF;
     IF NOT REGEXP_LIKE(p_name, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Название услуги должно содержать только буквы.');
        RETURN;
    END IF;
     IF p_description IS NULL  OR LENGTH(TRIM(p_description)) = 0 THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Описание услуги не может быть NULL.');
        RETURN;
    END IF;
     IF NOT REGEXP_LIKE(p_description, '^[[:alpha:],.\- ]+$') THEN
    sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Отзыв должен содержать только буквы.');
    RETURN;
END IF;

    -- Проверка на корректность входящих данных
    IF p_price < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: Цена не может быть отрицательной.');
        RETURN;
    END IF;

    UPDATE SERVICES
    SET name = TRIM(p_name),
        description = TRIM(p_description),
        price = p_price
    WHERE serviceID = p_serviceID;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Услуга изменена успешно.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Услуга с ID ' || p_ServiceID || ' не найдена.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Ошибка изменения услуги: ' || SQLERRM);
        RAISE;
END;

---------------------------------------------
--ДОБАВЛЕНИЕ НОВОГО СОТРУДНИКА
CREATE OR REPLACE PROCEDURE AddEmployee(    
    p_name IN EMPLOYEES.name%TYPE,    
    p_surname IN EMPLOYEES.surname%TYPE,    
    p_positions IN EMPLOYEES.positions%TYPE,
    p_phone IN EMPLOYEES.phone%TYPE,    
    p_email IN EMPLOYEES.email%TYPE,
    p_serviceID IN EMPLOYEES.serviceID%TYPE
)
IS
    v_EmailExists NUMBER;
    v_EmployeeID EMPLOYEES.employeeID%TYPE;
BEGIN
     IF p_name IS NULL OR LENGTH(TRIM(p_name)) = 0 or
        p_surname IS NULL OR LENGTH(TRIM(p_surname)) = 0 or
        p_positions IS NULL OR LENGTH(TRIM(p_positions)) = 0 or
        p_phone IS NULL OR LENGTH(TRIM(p_phone)) = 0 or
        p_email IS NULL OR LENGTH(TRIM(p_email)) = 0 then
        DBMS_OUTPUT.PUT_LINE('Ошибка: Поле не может быть пустым.');
        RETURN;
    END IF;

       IF NOT REGEXP_LIKE(p_name, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Имя сотрудника должно содержать только буквы.');
        RETURN;
    END IF;
       IF NOT REGEXP_LIKE(p_surname, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Фамилия сотрудника должна содержать только буквы.');
        RETURN;
    END IF;
       IF NOT REGEXP_LIKE(p_positions, '^[[:alpha:],.\- ]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('Ошибка: Специализация сотрудника должна содержать только буквы.');
        RETURN;
    END IF;

    -- Проверка на корректность входящих данных
    IF NOT IsEmailValid(p_email) THEN
        DBMS_OUTPUT.PUT_LINE('Error: Некорректный email.');
        RETURN;
    END IF;

    -- Проверка на существование услуги
    IF NOT IsServiceExists(p_serviceID) THEN
        DBMS_OUTPUT.PUT_LINE('Error: Услуга с ID ' || p_serviceID || ' не найдена.');
        RETURN;
    END IF;

    -- Проверка уникальности email
    SELECT COUNT(*)
    INTO v_EmailExists
    FROM EMPLOYEES
    WHERE email = TRIM(p_email);

    IF v_EmailExists > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Ошибка: Сотрудник с таким email уже существует.');
        RETURN;
    END IF;

    INSERT INTO EMPLOYEES (name, surname, positions, phone, email, serviceID)
    VALUES (TRIM(p_name), TRIM(p_surname), TRIM(p_positions), TRIM(p_phone), TRIM(p_email), p_serviceID);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Сотрудник добавлен успешно.');
EXCEPTION    
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Сотрудник с таким email уже существует.');
    WHEN OTHERS THEN     
        ROLLBACK;       
        DBMS_OUTPUT.PUT_LINE('Ошибка добавления сотрудника: ' || SQLERRM);
        RAISE;
END;
---------------------------------------------



BEGIN
    AddService(
        'Окрашивание',
        'окрашивание разной сложности по одной цене',
        200
    );
END;

BEGIN
    UpdateService(
        1,
        'Маникюр',
        'Все виды сложности',
        150
    );
END;

BEGIN
    AddEmployee(
        'Ирина',
        'Викторович',
        'мастер маникюра',
        '+144554798746',
        'irina@example.com',
        1
    );
END;