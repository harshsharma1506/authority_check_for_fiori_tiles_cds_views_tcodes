*&---------------------------------------------------------------------*
*& Report ZAUTH_CHECK
*&---------------------------------------------------------------------*
*&
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

TYPES: BEGIN of ty_range,
       sign TYPE char1,
       option TYPE char2,
       low TYPE agr_1251-low,
       high TYPE agr_1251-low,
       END OF ty_range.

CONSTANTS: c_key_cds VALUE 'S_RS_COMP1' TYPE C LENGTH 10,
           c_catalog VALUE 'CATALOGPAGE:'  TYPE C LENGTH 15.

DATA: wa_output TYPE ty_output,
      it_output TYPE STANDARD TABLE OF ty_output,
      cds_container TYPE agr_1251-low,
      wa_selops TYPE ty_range,
      catalog_container TYPE agr_buffi-url.

DATA: lr_columns TYPE REF TO cl_salv_columns_table,
        lr_column  TYPE REF TO cl_salv_column_table.

DATA: lr_alv TYPE REF TO cl_salv_table.
DATA: gr_functions TYPE REF TO cl_salv_functions.
DATA: gr_display   TYPE REF TO cl_salv_display_settings.

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
PERFORM get_data_bulk.
PERFORM get_alv USING it_output.

FORM get_data_bulk.

  IF t_code IS NOT INITIAL.
    SELECT tcode agr_name FROM agr_tcodes
      INTO (wa_output-object_name, wa_output-agr_name)
      WHERE tcode IN t_code.
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

FORM get_alv USING p_alv.
   CALL METHOD cl_salv_table=>factory
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

  try.
      lr_column ?= lr_columns->get_column( 'OBJECT' ).
      lr_column->set_long_text('Types Of Objects').
      lr_column ?= lr_columns->get_column( 'OBJECT_NAME' ).
      lr_column->set_long_text( 'Name of objects' ).
    catch cx_salv_not_found.
  endtry.

* Output
  lr_alv->display( ).
ENDFORM.
