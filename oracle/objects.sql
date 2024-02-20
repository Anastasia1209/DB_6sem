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

-- �������
--
--CREATE INDEX IX_Registration_ClientID ON REGISTRATION(clientID);
--CREATE INDEX IX_Employees_ServiceID ON EMPLOYEES(serviceID);
--CREATE INDEX IX_Reviews_EmployeeID ON REVIEWS(employeeID);
--
--DROP INDEX IX_Registration_ClientID;
--DROP INDEX IX_Employees_ServiceID;
--DROP INDEX IX_Reviews_EmployeeID;


-- �������������

CREATE OR REPLACE VIEW MyServiceView AS
SELECT serviceID, name, description, price
FROM SERVICES;

SELECT * FROM MyServiceView;

CREATE OR REPLACE VIEW MyEmployeeView AS
SELECT employeeID, name, surname, positions, serviceID, phone, email
FROM EMPLOYEES;


-----------------------------------------

--�������
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
--���������
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
        DBMS_OUTPUT.PUT_LINE('������: ���� �� ����� ���� ������.');
        RETURN;
    END if;

     IF NOT REGEXP_LIKE(p_name, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('������: �������� ������ ������ ��������� ������ �����.');
        RETURN;
    END IF;

    IF NOT REGEXP_LIKE(p_description, '^[[:alpha:],.\- ]+$') THEN
    sys.DBMS_OUTPUT.PUT_LINE('������: ����� ������ ��������� ������ �����, �������, �����, ������ � �������.');
    RETURN;
END IF;

    -- �������� �� ������������ �������� ������
   BEGIN
        IF p_price < 0 THEN
            sys.DBMS_OUTPUT.PUT_LINE('������: ���� �� ����� ���� �������������.');
            RETURN;
        END IF;
    EXCEPTION
        WHEN VALUE_ERROR THEN
            sys.DBMS_OUTPUT.PUT_LINE('������: ���� ������ ���� ������.');
            RETURN;
    END;

    INSERT INTO SERVICES (name, description, price)
    VALUES (TRIM(p_name), TRIM(p_description), p_price);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('������ ��������� �������.');
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('������ � ����� id ��� ����������.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('������ ���������� ������: ' || SQLERRM);
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
        sys.DBMS_OUTPUT.PUT_LINE('������: �������� ������ �� ����� ���� ������.');
        RETURN;
    END IF;
     IF NOT REGEXP_LIKE(p_name, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('������: �������� ������ ������ ��������� ������ �����.');
        RETURN;
    END IF;
     IF p_description IS NULL  OR LENGTH(TRIM(p_description)) = 0 THEN
        sys.DBMS_OUTPUT.PUT_LINE('������: �������� ������ �� ����� ���� NULL.');
        RETURN;
    END IF;
     IF NOT REGEXP_LIKE(p_description, '^[[:alpha:],.\- ]+$') THEN
    sys.DBMS_OUTPUT.PUT_LINE('������: ����� ������ ��������� ������ �����.');
    RETURN;
END IF;

    -- �������� �� ������������ �������� ������
    IF p_price < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: ���� �� ����� ���� �������������.');
        RETURN;
    END IF;

    UPDATE SERVICES
    SET name = TRIM(p_name),
        description = TRIM(p_description),
        price = p_price
    WHERE serviceID = p_serviceID;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('������ �������� �������.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('������ � ID ' || p_ServiceID || ' �� �������.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('������ ��������� ������: ' || SQLERRM);
        RAISE;
END;

---------------------------------------------
--���������� ������ ����������
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
        DBMS_OUTPUT.PUT_LINE('������: ���� �� ����� ���� ������.');
        RETURN;
    END IF;

       IF NOT REGEXP_LIKE(p_name, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('������: ��� ���������� ������ ��������� ������ �����.');
        RETURN;
    END IF;
       IF NOT REGEXP_LIKE(p_surname, '^[[:alpha:]]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('������: ������� ���������� ������ ��������� ������ �����.');
        RETURN;
    END IF;
       IF NOT REGEXP_LIKE(p_positions, '^[[:alpha:],.\- ]+$') THEN
        sys.DBMS_OUTPUT.PUT_LINE('������: ������������� ���������� ������ ��������� ������ �����.');
        RETURN;
    END IF;

    -- �������� �� ������������ �������� ������
    IF NOT IsEmailValid(p_email) THEN
        DBMS_OUTPUT.PUT_LINE('Error: ������������ email.');
        RETURN;
    END IF;

    -- �������� �� ������������� ������
    IF NOT IsServiceExists(p_serviceID) THEN
        DBMS_OUTPUT.PUT_LINE('Error: ������ � ID ' || p_serviceID || ' �� �������.');
        RETURN;
    END IF;

    -- �������� ������������ email
    SELECT COUNT(*)
    INTO v_EmailExists
    FROM EMPLOYEES
    WHERE email = TRIM(p_email);

    IF v_EmailExists > 0 THEN
        DBMS_OUTPUT.PUT_LINE('������: ��������� � ����� email ��� ����������.');
        RETURN;
    END IF;

    INSERT INTO EMPLOYEES (name, surname, positions, phone, email, serviceID)
    VALUES (TRIM(p_name), TRIM(p_surname), TRIM(p_positions), TRIM(p_phone), TRIM(p_email), p_serviceID);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('��������� �������� �������.');
EXCEPTION    
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('��������� � ����� email ��� ����������.');
    WHEN OTHERS THEN     
        ROLLBACK;       
        DBMS_OUTPUT.PUT_LINE('������ ���������� ����������: ' || SQLERRM);
        RAISE;
END;
---------------------------------------------



BEGIN
    AddService(
        '�����������',
        '����������� ������ ��������� �� ����� ����',
        200
    );
END;

BEGIN
    UpdateService(
        1,
        '�������',
        '��� ���� ���������',
        150
    );
END;

BEGIN
    AddEmployee(
        '�����',
        '����������',
        '������ ��������',
        '+144554798746',
        'irina@example.com',
        1
    );
END;