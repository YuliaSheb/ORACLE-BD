CREATE OR REPLACE PACKAGE json_parser AS
    --SELECT section
    FUNCTION parse_name_section(json_query_string JSON_ARRAY_T, search_name VARCHAR2,
                                table_name VARCHAR2 DEFAULT NULL)
                                RETURN VARCHAR2;
    FUNCTION parse_table_section(json_query_string JSON_ARRAY_T) RETURN VARCHAR2;
    FUNCTION parse_scalar_array(json_query_string JSON_ARRAY_T) RETURN VARCHAR2;
    FUNCTION parse_select(json_query_string JSON_OBJECT_T) RETURN VARCHAR2;
    FUNCTION condition_checker(json_query_string JSON_OBJECT_T, 
                                is_in_join_segment BOOLEAN DEFAULT FALSE) 
                                RETURN VARCHAR2;
    FUNCTION parse_where_section(json_query_string JSON_OBJECT_T) RETURN VARCHAR2;
    FUNCTION parse_compound_conditions(json_query_string JSON_ARRAY_T,
                                        join_condition VARCHAR2,
                                        is_in_join_segment BOOLEAN DEFAULT FALSE)
                                        RETURN VARCHAR2;
    FUNCTION parse_between_condition(json_values JSON_OBJECT_T) RETURN VARCHAR2;
    FUNCTION parse_join_section(json_query_string JSON_ARRAY_T) RETURN VARCHAR2;
    --DML section
     FUNCTION parse_values_as_array(json_columns JSON_ARRAY_T, 
                                    json_values JSON_ARRAY_T,
                                    new_val_type NUMBER) RETURN VARCHAR2;
    FUNCTION parse_values_as_select(json_columns JSON_ARRAY_T, 
                                    json_values JSON_OBJECT_T,
                                    new_val_type NUMBER) RETURN VARCHAR2;
    FUNCTION parse_new_values_section(json_columns JSON_ARRAY_T, 
                                    json_values JSON_ELEMENT_T,
                                    new_val_type NUMBER) RETURN VARCHAR2;
    FUNCTION parse_dml_section(json_query_string JSON_OBJECT_T) RETURN VARCHAR2;
    FUNCTION parse_JSON_to_SQL(json_query_string JSON_OBJECT_T) RETURN VARCHAR2;
END json_parser;


CREATE OR REPLACE PACKAGE BODY json_parser AS
    --SELECT section
    FUNCTION parse_name_section(json_query_string JSON_ARRAY_T, search_name VARCHAR2,
                                table_name VARCHAR2 DEFAULT NULL)
                                RETURN VARCHAR2
    IS
        res_tab_name VARCHAR2(51) := NULL;
        res_str VARCHAR2(300);
    BEGIN
        IF table_name IS NOT NULL THEN
            res_tab_name := table_name || '.';
        END IF;
        FOR i IN 0..json_query_string.get_size - 1
        LOOP
            res_str := res_str || ' ' || res_tab_name 
                    || json_query_string.get_String(i) || ',';
                    
        END LOOP;
        RETURN RTRIM(res_str, ',');
    END parse_name_section;
    
    
    FUNCTION parse_table_section(json_query_string JSON_ARRAY_T)
                                                    RETURN VARCHAR2
    IS
        res_str VARCHAR2(2000);
        table_name VARCHAR2(50);
        buff_json_object JSON_OBJECT_T;
        json_names JSON_ARRAY_T;
    BEGIN
        FOR i in  0..json_query_string.get_size - 1
        LOOP
            res_str := res_str || ' ' || json_query_string.get_string(i) || ',';
        END LOOP;
        RETURN RTRIM(res_str, ',');
    END parse_table_section;
    
    
    FUNCTION parse_scalar_array(json_query_string JSON_ARRAY_T) RETURN VARCHAR2
    IS
        res_str VARCHAR2(300) := '(';
        buff_json_element JSON_ELEMENT_T;
    BEGIN
        FOR i IN 0..json_query_string.get_size - 1
        LOOP
            buff_json_element := json_query_string.get(i);
            IF NOT buff_json_element.is_scalar THEN
                RAISE_APPLICATION_ERROR(-20005, 'Not scalar element was found in supposed scalar array');
            END IF;
            res_str := res_str || buff_json_element.to_string || ', '; 
        END LOOP;
        
        RETURN REPLACE(RTRIM(res_str, ', ') || ')', '"', '' || CHR(39));
    END parse_scalar_array;

FUNCTION parse_simple_condition(json_query_string JSON_OBJECT_T,
                                    is_in_join_segment BOOLEAN DEFAULT FALSE)
                                                        RETURN VARCHAR2
    IS
        res_str VARCHAR2(500);
        buff_json_element JSON_ELEMENT_T;
        buff_json_object JSON_OBJECT_T;
        res_tab_name VARCHAR2(51);
    BEGIN
        res_str := res_tab_name || json_query_string.get_string('col') || ' ';
 
        IF is_in_join_segment AND json_query_string.get_string('comparator') != '=' THEN
            RAISE_APPLICATION_ERROR(-20009, 'Unexpected value (' 
                || json_query_string.get_string('comparator') || ') expected (=) in "join section"');
        END IF;
        
        res_str := res_str || UPPER(json_query_string.get_string('comparator')) || ' ';
        buff_json_element := json_query_string.get('value'); 
        
        IF is_in_join_segment THEN
            res_str := res_str || json_query_string.get_string('value');
        ELSIF buff_json_element.is_scalar THEN
            res_str := res_str || buff_json_element.to_string;
        ELSIF buff_json_element.is_array THEN
            res_str := res_str || parse_scalar_array(TREAT(buff_json_element AS JSON_ARRAY_T));
        ELSE
            buff_json_object := TREAT(buff_json_element AS JSON_OBJECT_T);

            IF NOT buff_json_object.has('select') THEN
                RAISE_APPLICATION_ERROR(-20006, 'Not supported value in comparison');
            END IF;
            
            res_str := res_str || CHR(10) || '(' || CHR(10) 
                    || parse_select(buff_json_object.get_object('select')) || ')';
        END IF;
        RETURN REPLACE(res_str, '"', '' || CHR(39));
    END parse_simple_condition;


    FUNCTION parse_compound_conditions(json_query_string JSON_ARRAY_T,
                                        join_condition VARCHAR2,
                                        is_in_join_segment BOOLEAN DEFAULT FALSE)
                                        RETURN VARCHAR2
    IS
        buff_json_object JSON_OBJECT_T;
        res_str VARCHAR2(1000) := '(';
    BEGIN
        FOR i IN 0..json_query_string.get_size - 1
        LOOP
            buff_json_object := TREAT(json_query_string.get(i) AS JSON_OBJECT_T);
            res_str := res_str || condition_checker(buff_json_object, is_in_join_segment) 
                                || ' ' || join_condition || ' ';
        END LOOP;
        RETURN RTRIM(res_str, join_condition || ' ') || ')';
    END parse_compound_conditions;
    
    FUNCTION parse_between_condition(json_values JSON_OBJECT_T)
                                        RETURN VARCHAR2
    IS
    BEGIN
        RETURN '(' || json_values.get_String('col') || ' BETWEEN ' || json_values.get_Number('min') || ' AND ' || json_values.get_Number('max') || ')';
    END parse_between_condition;


    FUNCTION condition_checker(json_query_string JSON_OBJECT_T, 
                                is_in_join_segment BOOLEAN DEFAULT FALSE) 
                                RETURN VARCHAR2
    IS
    BEGIN
        IF json_query_string.has('or') THEN
            RETURN parse_compound_conditions(json_query_string.get_array('or'), 'OR', is_in_join_segment);
        ELSIF json_query_string.has('and') THEN
            RETURN parse_compound_conditions(json_query_string.get_array('and'), 'AND', is_in_join_segment);
        ELSIF json_query_string.has('comparison') THEN
            RETURN parse_simple_condition(json_query_string.get_object('comparison'), is_in_join_segment);
        ELSIF json_query_string.has('between') THEN
            RETURN parse_between_condition(json_query_string.get_object('between'));
        ELSE
            RAISE_APPLICATION_ERROR(-20004, 'There is no "comparison" in "where" section');
        END IF;   
    END condition_checker;


    FUNCTION parse_where_section(json_query_string JSON_OBJECT_T) RETURN VARCHAR2
    IS
    BEGIN
        RETURN condition_checker(json_query_string);
    END parse_where_section;


    FUNCTION parse_join_section(json_query_string JSON_ARRAY_T) RETURN VARCHAR2
    IS
        buff_json_object JSON_OBJECT_T;
        res_str VARCHAR2(2000);
    BEGIN
        FOR i IN 0..json_query_string.get_size - 1
        LOOP
            buff_json_object := TREAT(json_query_string.get(i) AS JSON_OBJECT_T);
            res_str := res_str
                    || UPPER(buff_json_object.get_string('join_type')) || ' JOIN ';
            IF buff_json_object.has('select') THEN
                res_str := res_str || CHR(10) || '(' || CHR(10) 
                        || parse_select(buff_json_object.get_object('select')) || ')';
            ELSIF buff_json_object.has('table') THEN
                res_str := res_str || buff_json_object.get_string('table');
            ELSE
                RAISE_APPLICATION_ERROR(-20008, 'There is no necessary join parameter in "join" section');
            END IF;
            res_str := res_str || CHR(10) || 'ON ' 
                        || condition_checker(buff_json_object.get_object('on'), TRUE)
                        || CHR(10);
        END LOOP;
        RETURN RTRIM(res_str, CHR(10));
    END parse_join_section;
    
    
    FUNCTION parse_group_by_section(json_query_string JSON_ARRAY_T) RETURN VARCHAR2
    IS
    BEGIN
        RETURN NULL;
    END parse_group_by_section;
    
    
    FUNCTION parse_select(json_query_string JSON_OBJECT_T) RETURN VARCHAR2
    IS
        res_str VARCHAR2(32000) := 'SELECT';
    BEGIN
        IF NOT json_query_string.has('what') THEN
            RAISE_APPLICATION_ERROR(-20002, 'There is no "what" section');
        END IF;
        res_str := res_str || 
            parse_table_section(json_query_string.get_array('what')) || CHR(10);
        IF NOT json_query_string.has('from') THEN
            RAISE_APPLICATION_ERROR(-20003, 'There is now "from" section');
        END IF;
        res_str := res_str || 'FROM' 
                || parse_name_section(json_query_string.get_array('from'), 'tab_name')
                || CHR(10);
        IF json_query_string.has('where') THEN
            res_str := res_str || 'WHERE ' 
                || parse_where_section(json_query_string.get_object('where'))
                || CHR(10);
        END IF;
        IF json_query_string.has('join') THEN
            res_str := res_str
                || parse_join_section(json_query_string.get_array('join'))
                || CHR(10);
        END IF;
        IF json_query_string.has('group by') THEN
            res_str := res_str
                || parse_group_by_section(json_query_string.get_array('group by'))
                || CHR(10);
        END IF;
        RETURN res_str;
    END parse_select;
