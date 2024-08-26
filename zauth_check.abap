*&---------------------------------------------------------------------*
*& Report ZAUTH_CHECK
*&---------------------------------------------------------------------*
*& Author - Harsh Sharma
*&---------------------------------------------------------------------*
REPORT zauth_check.

TABLES: agr_tcodes,
        agr_buffi,
        agr_1251,
        agr_hier,
        agr_hiert.

TYPES: BEGIN OF ty_output,
       object TYPE char35,
       object_name TYPE char50,
       agr_name TYPE agr_1251-agr_name,
       END OF ty_output.

TYPES: BEGIN OF ty_output_roles,
       agr_name TYPE agr_1251-agr_name,
       low  TYPE agr_1251-low,
       url  TYPE agr_buffi-url,
       tcode TYPE agr_tcodes-tcode,
       END OF ty_output_roles.


TYPES: BEGIN OF ty_range,
       sign TYPE char1,
       option TYPE char2,
       low TYPE agr_1251-low,
       high TYPE agr_1251-low,
       END OF ty_range.

CONSTANTS: c_key_cds VALUE 'S_RS_COMP1' TYPE c LENGTH 10,
           c_catalog VALUE 'CATALOGPAGE:'  TYPE c LENGTH 15,
           c_ui2 VALUE 'UI2'  TYPE c LENGTH 3,
           c_identifier VALUE '2C/' TYPE c LENGTH 3,
           c_tcode_key VALUE 'S_TCODE' TYPE c LENGTH 10.

DATA: wa_output TYPE ty_output,
      it_output TYPE STANDARD TABLE OF ty_output,
      wa_output_roles TYPE ty_output_roles,
      it_output_roles TYPE STANDARD TABLE OF ty_output_roles,
      it_output_roles_demo TYPE STANDARD TABLE OF ty_output_roles,
      cds_container TYPE agr_1251-low,
      wa_selops TYPE ty_range,
      catalog_container TYPE agr_buffi-url,
      role_sel_container TYPE agr_1251-low,
      role_sel_url_cont TYPE agr_buffi-url,
      role_sel_url_cont1 TYPE agr_buffi-url,
      l_text       type string,
      l_icon       type string,
      ind_count TYPE n,
      n type n.

DATA: lr_columns TYPE REF TO cl_salv_columns_table,
      lr_column  TYPE REF TO cl_salv_column_table.

DATA: lr_alv TYPE REF TO cl_salv_table.
DATA: gr_functions TYPE REF TO cl_salv_functions.
DATA: gr_display   TYPE REF TO cl_salv_display_settings.

SELECTION-SCREEN: BEGIN OF BLOCK b4 WITH FRAME TITLE TEXT-011.
    PARAMETERS: sel_rep1 RADIOBUTTON GROUP rad2,
                sel_rep2 RADIOBUTTON GROUP rad2.
SELECTION-SCREEN END OF BLOCK b4.

SELECTION-SCREEN: BEGIN OF BLOCK b03 WITH FRAME TITLE TEXT-010.
  SELECT-OPTIONS: role_sel FOR agr_1251-agr_name NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b03.

SELECTION-SCREEN: BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-006.
  SELECT-OPTIONS: t_code FOR agr_tcodes-tcode NO INTERVALS,
                  cds_view FOR agr_1251-low NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b01.

SELECTION-SCREEN: BEGIN OF BLOCK b02 WITH FRAME TITLE TEXT-007.
  PARAMETERS: sel_url RADIOBUTTON GROUP rad1,
              sel_cat RADIOBUTTON GROUP rad1.
  SELECT-OPTIONS: url_tile FOR agr_buffi-url NO INTERVALS,
                  catalog FOR agr_buffi-url NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b02.

START-OF-SELECTION.

IF sel_rep1 = 'X'.
  PERFORM get_data_for_roles_report.
  PERFORM get_alv USING it_output_roles.
ENDIF.


IF sel_rep2 = 'X'.
  PERFORM get_data_bulk_for_objects.
  PERFORM get_alv USING it_output.
ENDIF.

*&---------------------------------------------------------------------*
*& Form get_data_for_roles_report
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_data_for_roles_report .
  CONCATENATE '%' c_catalog '%' INTO role_sel_url_cont.
  CONCATENATE c_identifier '%' INTO role_sel_container.
  IF role_sel IS NOT INITIAL.
   SELECT a~agr_name, a~low, b~url FROM agr_1251 AS a
    RIGHT OUTER JOIN agr_buffi AS b ON a~agr_name = b~agr_name
     INTO CORRESPONDING FIELDS OF TABLE @it_output_roles
     WHERE a~agr_name IN @role_sel AND low LIKE @role_sel_container .   "cds view as key preference
   IF it_output_roles IS INITIAL.   " if cds view isnt there - we take T codes first
     SELECT agr_name, low FROM agr_1251 INTO (@wa_output_roles-agr_name, @wa_output_roles-tcode)
       WHERE agr_name IN @role_sel AND object = @c_tcode_key.
       APPEND wa_output_roles TO it_output_roles.
     ENDSELECT.
     SELECT url FROM agr_buffi INTO (@wa_output_roles-url) " Now we take fiori tiles
       WHERE agr_name IN @role_sel.
       APPEND wa_output_roles TO it_output_roles.
     ENDSELECT.
   ELSE.                                                   " in case CDS view is there - so now we just have to loop to inclide T codes
     LOOP AT it_output_roles INTO wa_output_roles.
       SELECT low FROM agr_1251 INTO (@wa_output_roles-tcode) WHERE agr_name IN @role_sel AND object = @c_tcode_key.
         MODIFY it_output_roles FROM wa_output_roles.
       ENDSELECT.
     ENDLOOP.
     SELECT agr_name, low FROM agr_1251 INTO (@wa_output_roles-agr_name, @wa_output_roles-tcode)
       WHERE agr_name IN @role_sel AND object = @c_tcode_key.
       INSERT wa_output_roles INTO it_output_roles INDEX sy-index + 1.
     ENDSELECT.
     CLEAR wa_output_roles.
      SELECT agr_name, url FROM agr_buffi INTO (@wa_output_roles-agr_name, @wa_output_roles-url) " Now we take fiori tiles
       WHERE agr_name IN @role_sel.
       INSERT wa_output_roles INTO it_output_roles INDEX sy-index + 1.
     ENDSELECT.
   ENDIF.
ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form get_data_bulk_for_objects
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*

FORM get_data_bulk_for_objects.

  IF t_code IS NOT INITIAL.
    SELECT low agr_name FROM agr_1251
      INTO (wa_output-object_name, wa_output-agr_name)
      WHERE low IN t_code AND object = c_tcode_key.
      wa_output-object = TEXT-004.
      APPEND wa_output TO it_output.
    ENDSELECT.
  ENDIF.

  IF cds_view IS NOT INITIAL.
   LOOP AT  cds_view INTO wa_selops.
    CONCATENATE '%' wa_selops-low '%' INTO cds_container.
    SELECT low agr_name FROM agr_1251
      INTO (wa_output-object_name, wa_output-agr_name)
      WHERE object = c_key_cds AND low LIKE cds_container.
      wa_output-object = TEXT-005.
      APPEND wa_output TO it_output.
    ENDSELECT.
   ENDLOOP.
  ENDIF.

  IF sel_url = 'X' AND url_tile IS NOT INITIAL.
    SELECT url agr_name FROM agr_buffi
      INTO (wa_output-object_name,wa_output-agr_name)
      WHERE url IN url_tile.
      wa_output-object = TEXT-008.
      APPEND wa_output TO it_output.
    ENDSELECT.

  ELSEIF sel_cat = 'X' AND catalog IS NOT INITIAL.
    CLEAR wa_selops.
    LOOP AT catalog INTO wa_selops.
      CONCATENATE '%' c_catalog wa_selops-low '%' INTO catalog_container.
      SELECT agr_name url FROM agr_buffi INTO ( wa_output-agr_name , wa_output-object_name )
        WHERE url LIKE catalog_container.
        wa_output-object = TEXT-009.
        APPEND wa_output TO it_output.
       ENDSELECT.
     ENDLOOP.
   ENDIF.
ENDFORM.

FORM get_alv USING p_alv RAISING cx_salv_msg.
   CALL METHOD cl_salv_table=>factory
*    EXPORTING
*      r_container = data_container
    IMPORTING
      r_salv_table = lr_alv   " Basis Class Simple ALV Tables
    CHANGING
      t_table      =  p_alv.
** To Display the Sort, Filter Export, Etc,. options
  gr_functions = lr_alv->get_functions( ).
  gr_functions->set_all( abap_true ).
  gr_display = lr_alv->get_display_settings( ). "Display Settings

*  Header
  gr_display->set_list_header( 'Authority Roles Report' ). " Heading for the ALV

*   Zebra pattern
  gr_display->set_striped_pattern( abap_true ). " To set the striped Pattern

  lr_columns = lr_alv->get_columns( ). " Fetch columns
IF sel_rep2 = 'X'.
  TRY.
      lr_column ?= lr_columns->get_column( 'OBJECT' ).
      lr_column->set_long_text('Types Of Objects').
      lr_column ?= lr_columns->get_column( 'OBJECT_NAME' ).
      lr_column->set_long_text( 'Name of objects' ).
    CATCH cx_salv_not_found.
  ENDTRY.
ELSEIF sel_rep1 = 'X'.
  TRY.
      lr_column ?= lr_columns->get_column( 'AGR_NAME' ).
      lr_column->set_long_text('Roles').
      lr_column ?= lr_columns->get_column( 'LOW' ).
      lr_column->set_long_text( 'CDS views id' ).
      lr_column ?= lr_columns->get_column('URL').
      lr_column->set_medium_text( 'FIORI Tiles' ).
      lr_column->set_long_text( 'FIORI Tiles' ).

      lr_column ?= lr_columns->get_column('TCODE').
      lr_column->set_medium_text( 'T code' ).
      lr_column->set_long_text( 'T code' ).
      lr_column->set_short_text( 'T code' ).
    CATCH cx_salv_not_found.
  ENDTRY.
ENDIF.

* Output
  lr_alv->display( ).
ENDFORM.
