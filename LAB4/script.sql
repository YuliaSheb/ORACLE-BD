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
