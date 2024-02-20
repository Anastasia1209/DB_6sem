use SALON;

--последовательности
CREATE SEQUENCE ServiceIDSequence
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 10;

SELECT NEXT VALUE FOR ServiceIDSequence;

--------------------
CREATE SEQUENCE EmployeeIDSequence
START WITH 1
INCREMENT BY 1
NO MINVALUE
NO MAXVALUE
CACHE 10;

----индексы

--CREATE INDEX IX_Registration_ClientID ON REGISTRATION(clientID);
--CREATE INDEX IX_Employees_ServiceID ON EMPLOYEES(serviceID);
--CREATE INDEX IX_Reviews_EmployeeID ON REVIEWS(employeeID);


--drop index IX_Registration_ClientID ON REGISTRATION;
--drop index IX_Employees_ServiceID ON EMPLOYEES;
--drop index IX_Reviews_EmployeeID ON CLIENTS;

--представления
CREATE VIEW MyServiceView
AS
SELECT serviceID, name, description, price
FROM SERVICS;

SELECT * FROM MyServiceView;

---------------------
CREATE VIEW MyEmployeeView
AS
SELECT employeeID, name, surname, positions, serviceID, phone, email
FROM EMPLOYEES;

-----------------------------
drop view MyServiceView;
drop view MyEmployeeView;
--------------------------------------------
go
--процедуры
CREATE OR ALTER PROCEDURE AddService
    @p_name NVARCHAR(100),
    @p_description NVARCHAR(255),
    @p_price DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    IF @p_name IS NULL OR LTRIM(RTRIM(@p_name)) = '' OR
       @p_description IS NULL OR LTRIM(RTRIM(@p_description)) = '' OR
       @p_price IS NULL
    BEGIN
        PRINT 'Ошибка: Поле не может быть пустым.';
        RETURN;
    END;

    IF NOT @p_name LIKE '[a-zA-Z]%' COLLATE Latin1_General_BIN2
    BEGIN
        PRINT 'Ошибка: Название услуги должно содержать только буквы.';
        RETURN;
    END;

    IF NOT @p_description LIKE '[a-zA-Z,.\- ]%' COLLATE Latin1_General_BIN2
    BEGIN
        PRINT 'Ошибка: Описание услуги должно содержать только буквы, запятые, точки, дефисы и пробелы.';
        RETURN;
    END;

    IF @p_price < 0
    BEGIN
        PRINT 'Ошибка: Цена не может быть отрицательной.';
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO SERVICS (name, description, price)
        VALUES (LTRIM(RTRIM(@p_name)), LTRIM(RTRIM(@p_description)), @p_price);

        PRINT 'Услуга добавлена успешно.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2601
        BEGIN
            PRINT 'Услуга с таким id уже существует.';
        END
        ELSE
        BEGIN
            PRINT 'Ошибка добавления услуги: ' + ERROR_MESSAGE();
        END
    END CATCH;
END;
go
---------------------------------------
CREATE OR ALTER PROCEDURE UpdateService(
    @p_serviceID INT,
    @p_name NVARCHAR(100),
    @p_description NVARCHAR(255),
    @p_price DECIMAL(10,2)
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @p_name IS NULL OR LTRIM(RTRIM(@p_name)) = ''
    BEGIN
        PRINT 'Ошибка: Название услуги не может быть пустым.';
        RETURN;
    END;

    IF @p_description IS NULL OR LTRIM(RTRIM(@p_description)) = ''
    BEGIN
        PRINT 'Ошибка: Описание услуги не может быть пустым.';
        RETURN;
    END;

    IF @p_price < 0
    BEGIN
        PRINT 'Ошибка: Цена не может быть отрицательной.';
        RETURN;
    END;

    UPDATE SERVICS
    SET name = LTRIM(RTRIM(@p_name)),
        description = LTRIM(RTRIM(@p_description)),
        price = @p_price
    WHERE serviceID = @p_serviceID;

    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Услуга с ID ' + CAST(@p_serviceID AS NVARCHAR) + ' не найдена.';
        RETURN;
    END;

    PRINT 'Услуга изменена успешно.';
END;
go

-----------------------------------------------------------------
CREATE OR ALTER PROCEDURE AddEmployee
    @p_name NVARCHAR(50),
    @p_surname NVARCHAR(50),
    @p_positions NVARCHAR(50),
    @p_phone NVARCHAR(20),
    @p_email NVARCHAR(100),
    @p_serviceID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @p_name IS NULL OR LTRIM(RTRIM(@p_name)) = '' OR
       @p_surname IS NULL OR LTRIM(RTRIM(@p_surname)) = '' OR
       @p_positions IS NULL OR LTRIM(RTRIM(@p_positions)) = '' OR
       @p_phone IS NULL OR LTRIM(RTRIM(@p_phone)) = '' OR
       @p_email IS NULL OR LTRIM(RTRIM(@p_email)) = ''
    BEGIN
        PRINT 'Ошибка: Поле не может быть пустым.';
        RETURN;
    END;

    IF NOT @p_name LIKE '[a-zA-Z]%' COLLATE Latin1_General_BIN2
    BEGIN
        PRINT 'Ошибка: Имя сотрудника должно содержать только буквы.';
        RETURN;
    END;

    IF NOT @p_surname LIKE '[a-zA-Z]%' COLLATE Latin1_General_BIN2
    BEGIN
        PRINT 'Ошибка: Фамилия сотрудника должна содержать только буквы.';
        RETURN;
    END;

    IF NOT @p_positions LIKE '[a-zA-Z,.\- ]%' COLLATE Latin1_General_BIN2
    BEGIN
        PRINT 'Ошибка: Специализация сотрудника должна содержать только буквы, запятые, точки, дефисы и пробелы.';
        RETURN;
    END;

    IF dbo.IsEmailValid(@p_email) = 1
    BEGIN
        PRINT 'Ошибка: Некорректный email.';
        RETURN;
    END;

    IF NOT dbo.IsServiceExists(@p_serviceID) = 1
    BEGIN
        PRINT 'Ошибка: Услуга с ID ' + CAST(@p_serviceID AS NVARCHAR) + ' не найдена.';
        RETURN;
    END;

    IF EXISTS (SELECT 1 FROM EMPLOYEES WHERE email = LTRIM(RTRIM(@p_email)))
    BEGIN
        PRINT 'Ошибка: Сотрудник с таким email уже существует.';
        RETURN;
    END;

    BEGIN TRY
        INSERT INTO EMPLOYEES (name, surname, positions, phone, email, serviceID)
        VALUES (LTRIM(RTRIM(@p_name)), LTRIM(RTRIM(@p_surname)), LTRIM(RTRIM(@p_positions)),
                LTRIM(RTRIM(@p_phone)), LTRIM(RTRIM(@p_email)), @p_serviceID);
        COMMIT;
        PRINT 'Сотрудник добавлен успешно.';
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627
        BEGIN
            PRINT 'Сотрудник с таким email уже существует.';
        END
        ELSE
        BEGIN
            PRINT 'Ошибка добавления сотрудника: ' + ERROR_MESSAGE();
        END;
        ROLLBACK;
    END CATCH;
END;

go
--------------------------------------------------------

--------------------------------------------------------

--функции
CREATE OR ALTER FUNCTION dbo.IsEmailValid(@p_Email NVARCHAR(100)) 
RETURNS BIT
AS
BEGIN
    DECLARE @v_Pattern NVARCHAR(100) = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

    IF @p_Email LIKE @v_Pattern
        RETURN 1;
    ELSE
        RETURN 0;
		 RETURN 0;
end;
GO
drop function dbo.IsEmailValid;


CREATE FUNCTION dbo.IsEmployeeExists(@p_employeeID INT) 
RETURNS BIT
AS
BEGIN
    DECLARE @v_Count INT;

    SELECT @v_Count = COUNT(*) FROM EMPLOYEES WHERE employeeID = @p_employeeID;

    RETURN CASE WHEN @v_Count > 0 THEN 1 ELSE 0 END;
END;
GO
----------------------------------
CREATE FUNCTION dbo.IsServiceExists(@p_serviceID INT) 
RETURNS BIT
AS
BEGIN
    DECLARE @v_Count INT;

    SELECT @v_Count = COUNT(*) FROM SERVICS WHERE serviceID = @p_serviceID;

    RETURN CASE WHEN @v_Count > 0 THEN 1 ELSE 0 END;
END;
GO
------------------------------------------------------


EXEC AddService 
    @p_name = N'manicure',
    @p_description = N'service description',
    @p_price = 100.00;


EXEC UpdateService
    @p_serviceID = 1,
    @p_name = N'manicure',
    @p_description = N'new service description',
    @p_price = 150.00;


EXEC AddEmployee 
    @p_name = N'Ana',
    @p_surname = N'Gol',
    @p_positions = N'manicure',
    @p_phone = N'12345678',
    @p_email = N'tese@example.com',
    @p_serviceID = 1;

