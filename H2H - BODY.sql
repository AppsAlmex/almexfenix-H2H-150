create or replace PACKAGE BODY "XXALM_H2H_BS" 
IS
  --HeaderInfo
    h_cuenta VARCHAR2(10);
    h_fecha_ini VARCHAR2(6);
    h_fecha_fin VARCHAR2(6);
    h_saldo_op_inicial NUMBER;
    h_moneda VARCHAR2(3);
    h_titular VARCHAR2(23);
    h_indicador_saldo VARCHAR2(10);
    --MovsInfo
    m_fecha_op VARCHAR2 (6);
    m_fecha_val VARCHAR2 (6);
    m_codigo_mov VARCHAR2 (3);
    m_cargo_abono VARCHAR2 (1);
    m_importe VARCHAR2 (20);
    m_dato VARCHAR2 (10);
    m_concepto VARCHAR2 (28);
    m_codigo_dato VARCHAR2 (2);
    m_referencia_a VARCHAR2 (38);
    m_referencia VARCHAR2 (38);
    --TotalesInfo
    t_indicador_saldo    VARCHAR2(10);
    t_saldo_v_ini    NUMBER;
    t_saldo_v_fin    NUMBER;
    t_no_cargos    NUMBER;
    t_importe_cargos    NUMBER;
    t_no_bonos    NUMBER;
    t_importe_bonos    NUMBER;
    t_saldo_op_final    NUMBER;
    t_moneda    VARCHAR2(3);

  --    @AUTHOR: NANCY RUBI BRISEÑO SERRANO  
  --Consultoría Dotti Consulting 
  --    Diciembre 2021
  --------------------------------------------------------------------------------     
  PROCEDURE readFile IS

  uFile UTL_FILE.FILE_TYPE;
  l_path varchar(1000) := 'H2H';
  op_file UTL_FILE.FILE_TYPE;
  v_row VARCHAR(2000);
  numLines NUMBER :=0;
  currentLine NUMBER := 0;    
  id_header NUMBER;
  posRef NUMBER;

  BEGIN
  BEGIN
 FOR f in (SELECT filename, id_cabecero from XXALM_H2H_FILES)

    LOOP
    dbms_output.put_line(f.id_cabecero||'- Abriendo archivo: '||f.filename);
    INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Lectura de archivo'|| f.filename,sysdate,f.id_cabecero);
    COMMIT;
    id_header:=f.id_cabecero;
    uFile:= UTL_FILE.FOPEN(l_path,f.filename,'R');

 LOOP

 BEGIN   
      UTL_FILE.GET_LINE(uFile,v_row);
   CASE 
   WHEN substr(v_row,1,2) = '11' THEN 
       --HeaderInfo
            h_cuenta := substr(v_row,11,10);
            h_fecha_ini := substr(v_row,21,6);
            h_fecha_fin := substr(v_row,27,6);
            
            CASE
                WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,34,14), '*'), ' +-.0123456789', ' '))) IS NULL
                    THEN h_saldo_op_inicial := to_number(formatAmount(substr(v_row,34,14),'.'));             
            END CASE;
--            h_saldo_op_inicial := to_number(formatAmount(substr(v_row,34,14),'.'));
            h_moneda := substr(v_row,48,3);
            h_titular := substr(v_row,52,23);

        CASE WHEN trim((substr(v_row,33,1))) = '2' THEN 
           h_indicador_saldo:= 'POSITIVO';
           ELSE
           H_indicador_saldo:= 'NEGATIVO';
           END CASE;
            INSERT INTO XXALM_H2H_HEADER VALUES (id_header,  h_cuenta,h_fecha_ini,h_fecha_fin,h_saldo_op_inicial,h_moneda,h_titular,h_indicador_saldo);
   WHEN substr(v_row,1,2) = '22' THEN 
        m_fecha_op := substr(v_row,11,6);
        m_fecha_val := substr(v_row,17,6);
        m_codigo_mov := substr(v_row,25,3);
        m_cargo_abono := substr(v_row,28,1);
        m_importe := formatAmount(substr(v_row,29,14));
        m_dato := substr(v_row,43,10);
        m_concepto := substr(v_row,53,28);
   WHEN substr(v_row,1,2) = '23' THEN    
        m_codigo_dato := substr(v_row,3,2);
        posRef:= instr(substr(v_row,5,38), 'CUENTA/MOVTO:');
        CASE WHEN posRef>0 THEN 
            m_referencia_a := substr(v_row,20,23);
        ELSE 
            m_referencia_a := substr(v_row,5,38);
        END CASE;
        m_referencia := substr(v_row,43,38); 
        currentLine := currentLine +1;
        INSERT INTO XXALM_H2H_LINES VALUES (currentLine,m_fecha_op,m_fecha_val,m_codigo_mov,m_cargo_abono,m_importe,m_dato,m_concepto,m_codigo_dato,m_referencia_a,m_referencia,id_header);
   WHEN substr(v_row,1,2) = '32' THEN
   --Totales Line 32
           CASE WHEN trim((substr(v_row,6,2))) = '2' THEN 
           t_indicador_saldo:= 'POSITIVO';
           ELSE
           t_indicador_saldo:= 'NEGATIVO';
           END CASE;
           
           /*Se agrega validacion para obtener unicamente valores numericos*/
           CASE
                WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,43,35), '*'), ' +-.0123456789', ' '))) IS NULL
                    THEN t_saldo_v_ini := to_number(formatAmount(substr(v_row,43,35),'.'))  ;
                WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,8,35), '*'), ' +-.0123456789', ' '))) IS NULL
                    THEN t_saldo_v_fin := to_number(formatAmount(substr(v_row,8,35),'.'));              
            END CASE;
--    t_saldo_v_ini := to_number(formatAmount(substr(v_row,43,35),'.'));  
--    t_saldo_v_fin := to_number(formatAmount(substr(v_row,8,35),'.'));
   WHEN substr(v_row,1,2) = '33' THEN
   
        CASE
            WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,21,5), '*'), ' +-.0123456789', ' '))) IS NULL
                THEN t_no_cargos := to_number(substr(v_row,21,5));
            WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,26,14), '*'), ' +-.0123456789', ' '))) IS NULL
                THEN t_importe_cargos := to_number(substr(v_row,26,14));  
            WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,40,5), '*'), ' +-.0123456789', ' '))) IS NULL
                THEN t_no_bonos := to_number(substr(v_row,40,5));  
            WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,45,14), '*'), ' +-.0123456789', ' '))) IS NULL
                THEN t_importe_bonos := to_number(substr(v_row,45,14));     
            WHEN LENGTH (TRIM (TRANSLATE ( nvl(substr(v_row,60,14), '*'), ' +-.0123456789', ' '))) IS NULL
                THEN t_saldo_op_final := to_number(formatAmount(substr(v_row,60,14),'.'));  
              
        END CASE;
               
--    t_no_cargos := to_number(substr(v_row,21,5));
--    t_importe_cargos := to_number(substr(v_row,26,14));
--    t_no_bonos := to_number(substr(v_row,40,5));
--    t_importe_bonos := to_number(substr(v_row,45,14));
--    t_saldo_op_final := to_number(formatAmount(substr(v_row,60,14),'.'));
        t_moneda := substr(v_row,74,3);
    
    INSERT INTO XXALM_H2H_TOTAL VALUES (TOTALES_LINES_SEQ.nextval,id_header,t_indicador_saldo,t_saldo_v_ini,t_saldo_v_fin,t_no_cargos,t_importe_cargos,t_no_bonos,
    t_importe_bonos,t_saldo_op_final,t_moneda);

    INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Registro exitoso en tablas para archivo: '|| f.filename,sysdate,f.id_cabecero);
    COMMIT;
   ELSE 
   dbms_output.put_line('Problemas con el archivo');     
    INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Se ha producido un error: se ha encontrado una combinacion de dígitos inesperada en la lectura del cuaderno 43. '|| f.filename,sysdate,f.id_cabecero);
    COMMIT;
    END CASE; 
    exception WHEN No_Data_Found Then Exit;
     WHEN OTHERS THEN
   INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Excepcion en lectura de archivo: '||f.filename,sysdate,-1);
   COMMIT;
    END;


     END LOOP;
      UTL_FILE.FCLOSE(uFile);
    END LOOP;
   EXCEPTION WHEN OTHERS THEN
   ROLLBACK;
   INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Error en proceso lectura',sysdate,-1);
   COMMIT;
   END;


  END;
--------------------------------------------------------------------------------     

 PROCEDURE writeMT940 IS

  uFile UTL_FILE.FILE_TYPE;
 -- f_name VARCHAR2(1000):=  'HHCV.00000400.018.HHCV000.F211118.5161991.txt';
  --'H22TEST.txt';
  op_file UTL_FILE.FILE_TYPE;
  l_path varchar(1000) := 'H2H';
  f_name VARCHAR2(1000):= 'MT940.txt';
  v_row VARCHAR2 (2000);
  idheader NUMBER;
  crdt_dbt VARCHAR2(1);
  blobFile BLOB;
  l_zip_file blob;l_clob CLOB;
  l_step PLS_INTEGER := 12000; 
  l_offset     INT := 1;  
  l_UCM VARCHAR2(1000):= 'https://fa-enkq-test-saasfaprod1.fa.ocs.oraclecloud.com/fscmRestApi/resources/11.13.18.05/erpintegrations';
  l_user VARCHAR2(100); 
  l_pass  VARCHAR2(100); 
  l_wallet VARCHAR2(100);
  l_json CLOB;
  l_response CLOB;
  CD_open VARCHAR2(1);
  CD_close VARCHAR2(1);
  refMov VARCHAR2(16);
  pos NUMBER;
  iteraciones NUMBER :=0;
  i NUMBER :=0;
  idDoc NUMBER:=0;
  p_clob CLOB;
  l_BU VARCHAR2(100);
  l_cust_account VARCHAR2(20);
  l_cust_ref VARCHAR2(50);
  l_doc_id VARCHAR2(50);
  l_fileNameResponse VARCHAR2(50);
  v_error VARCHAR2(1000);
  l_consecutivo     VARCHAR2(20);
  l_contador        NUMBER:=0;
  l_Bu_id           VARCHAR2(20);
  l_site VARCHAR2(100);
  l_date VARCHAR2(10);
  l_flag NUMBER:=0;
  BEGIN 
  uFile:= UTL_FILE.FOPEN(l_path,f_name,'W');
  --LEER CABECERO
  dbms_lob.createtemporary(blobFile, TRUE);
  BEGIN

   dbms_lob.createtemporary(blobFile, TRUE);
  Select count(*) into iteraciones from XXALM_H2H_HEADER;
    INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Inicia construccion MT9402' ,sysdate,-1);
    COMMIT;
  FOR doc in (Select id_cabecero  from XXALM_H2H_HEADER)
   LOOP

    i:=i+1;
          SELECT id_cabecero, cuenta,  fecha_ini,fecha_fin, saldo_op_inicial, 
          CASE WHEN moneda= 'MXP' THEN 
          'MXN' else
          moneda end mon,
          CASE WHEN indicador_saldo = 'POSITIVO' then 
           'C'
          ELSE 
           'D'
          END saldo into
           idheader, h_cuenta ,h_fecha_ini , h_fecha_fin , h_saldo_op_inicial , h_moneda, CD_open FROM XXALM_H2H_HEADER where id_cabecero=doc.id_cabecero ;
         --LEER TOTALES
         SELECT saldo_v_ini,saldo_v_fin,saldo_op_final, importe_cargos, importe_bonos, no_bonos, no_cargos,
          CASE WHEN indicador_saldo = 'POSITIVO' then 
           'C'
          ELSE 
           'D'
          END saldo
          into  
            t_saldo_v_ini,
            t_saldo_v_fin,
            t_saldo_op_final, 
            t_importe_cargos,
            t_importe_bonos,
            t_no_bonos,
            t_no_cargos,
            CD_close
            FROM XXALM_H2H_TOTAL WHERE id_cabecero = idheader;
          --INICIA CONSTRUCCION DE FORMATO MT940
          IF(i=1) THEN
          v_row:= ':20:'||h_fecha_ini||CHR(10);
          UTL_FILE.PUT(uFile,v_row);
          blobFile:= utl_raw.cast_to_raw(v_row);
          ELSE
            v_row:= ':20:'||h_fecha_ini||CHR(10);
            UTL_FILE.PUT(uFile,v_row);
          DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));
          END IF;
            v_row:=  ':25:'||h_cuenta||CHR(10);
            UTL_FILE.PUT(uFile,v_row);
           DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));
            v_row:=  ':28:'||h_fecha_ini||'/'||h_cuenta||CHR(10);
            UTL_FILE.PUT(uFile,v_row);
           DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));
            --dbms_output.put_line(v_row);
            v_row:=  ':60F:'||CD_open||h_fecha_ini||h_moneda||TRIM(replace(to_char(h_saldo_op_inicial,'099999999999D99'),'.',','))||CHR(10);
            UTL_FILE.PUT(uFile,v_row);
           DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));


                FOR mov in (SELECT 
                            id_line,
                           fecha_op,
                           fecha_val,
                           codigo_leyenda,
                           cargo_abono,
                           importe,
                           dato,
                           concepto,
                           codigo_dato,
                           referencia_ampliada,
                           referencia
                           FROM XXALM_H2H_LINES 
                           WHERE id_cabecero= idheader order by id_line asc) 
                LOOP

                l_cust_ref:=substr(mov.referencia,1,16);
                --Obtener BU, Site y Customer Account
                 l_cust_account:= '';  
                 l_site :='';
                 l_BU :='';
                 getInfoAR(h_cuenta,l_cust_ref,l_BU,l_site,l_cust_account);

                l_fLAG:= 0;
                   CASE WHEN pos>1 THEN
                           refMov:=substr(mov.referencia_ampliada,pos+1,16);
                           ELSE
                           refMov:=substr(mov.referencia_ampliada,1,16);

                           END CASE;
                           CASE WHEN mov.cargo_abono = '2' THEN 
                           crdt_dbt := 'C'; --CRDT
                            --Standar Receipts
                           --Excepcion para las sig referencias 
                           IF  instr(mov.referencia,'SPEI DEVUELTO') = 0 and instr(mov.concepto,'SPEI DEVUELTO') = 0 THEN --Concepto y referenecia
                           --Transferencia
                            CASE WHEN mov.codigo_leyenda in ( 'C81','CA9','CC2','E17','E27','H02','H09','M50','M97','N06','N16','P14','T09','T17','T20','T22','T31','TK7','W01','W02','W41','W42','Y16') THEN
                                    l_contador :=l_contador+1;
                                    l_consecutivo:='20'|| mov.fecha_val||'-'||lpad(to_char(l_contador),3,'0');
                                    l_fLAG := 1;
                                 INSERT INTO XXALM_H2H_RECEIPTS VALUES(RECEIPT_SEQ.nextval,l_BU,mov.fecha_val,'Transferencia',replace(mov.importe,',','.'),h_moneda,l_cust_ref,l_site,l_cust_account,l_consecutivo,idheader,h_cuenta,'STAND',mov.id_line);                         

                                COMMIT;
                                 --Cheque
                              WHEN mov.codigo_leyenda IN ('C07','Y02','Y05','Y06') THEN
                                 l_contador :=l_contador+1;
                                 l_consecutivo:='20'|| mov.fecha_val||'-'||lpad(to_char(l_contador),3,'0');
                                 l_fLAG := 1;
                                 INSERT INTO XXALM_H2H_RECEIPTS VALUES(RECEIPT_SEQ.nextval,l_BU,mov.fecha_val,'Cheque',replace(mov.importe,',','.'),h_moneda,l_cust_ref,l_site,l_cust_account,l_consecutivo,idheader,h_cuenta,'STAND',mov.id_line);                         

                                COMMIT;
                               --Efectivo
                                WHEN mov.codigo_leyenda IN ( 'AA7','Y01','Y15')  THEN
                                   l_contador :=l_contador+1;
                                   l_consecutivo:='20'|| mov.fecha_val||'-'||lpad(to_char(l_contador),3,'0');
                                   l_fLAG := 1;
                               INSERT INTO XXALM_H2H_RECEIPTS VALUES(RECEIPT_SEQ.nextval,l_BU,mov.fecha_val,'Efectivo',replace(mov.importe,',','.'),h_moneda,l_cust_ref,l_site,l_cust_account,l_consecutivo,idheader,h_cuenta,'STAND',mov.id_line);                         
                                COMMIT;    
                                ELSE 
                                  INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Se encontró un código no identificado: ' || mov.codigo_leyenda ,sysdate,doc.id_cabecero);
                            END CASE;
                            END IF;

                           WHEN mov.cargo_abono = '1'THEN
                           crdt_dbt := 'D'; --DBT
                           ELSE 
                           crdt_dbt:='';
                           END CASE;

                           pos:= instr(mov.referencia_ampliada,'/');


                        v_row:=  ':61:'||mov.fecha_val||substr(mov.fecha_val,3,6)||crdt_dbt||mov.importe||'N'||mov.codigo_leyenda||substr(mov.referencia,1,16)||'//'||refMov||CHR(10);
                        UTL_FILE.PUT(uFile,v_row);
                        DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));  


                        IF (l_flag =1) THEN --Se usa para las líneas que van a crear recibos ( se asocia el consecutivo del recibo)
                         v_row:=  ':86:'||l_consecutivo||' '||mov.concepto||CHR(10);
                         UTL_FILE.PUT(uFile,v_row);
                        DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));
                        ELSE
                         v_row:=  ':86:'||mov.concepto||CHR(10);
                         UTL_FILE.PUT(uFile,v_row);
                        DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));
                        END If;

                END LOOP; --Termina iteracion lineas

                 IF (i < iteraciones) THEN
                   v_row:=  ':62F:'||CD_close||h_fecha_fin||h_moneda||TRIM(replace(to_char(t_saldo_op_final,'099999999999D99'),'.',','))||CHR(10);
                   UTL_FILE.PUT(uFile,v_row);
                 DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));
                   UTL_FILE.PUT_LINE(uFile,'-');
                 DBMS_LOB.append(blobFile, utl_raw.cast_to_raw('-'||CHR(10)));
                 ELSE 
                   v_row:=  ':62F:'||CD_close||h_fecha_fin||h_moneda||TRIM(replace(to_char(t_saldo_op_final,'099999999999D99'),'.',','));
                   UTL_FILE.PUT(uFile,v_row);
                 DBMS_LOB.append(blobFile, utl_raw.cast_to_raw(v_row));

                 END IF;


 END LOOP;
 UTL_FILE.FCLOSE(uFile) ;

  EXCEPTION WHEN No_Data_Found THEN 
  v_error:= SUBSTR(SQLERRM, 1 , 1000);
   INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'No hay informacion en tablas para MT940. '||v_error ,sysdate,-1);
   COMMIT;
   dbms_output.put_line(SQLERRM);
   WHEN OTHERS THEN
   v_error:= SUBSTR(SQLERRM, 1 , 1000);
     INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Error on MT940: '||v_error,sysdate,-1);
     COMMIT;
     dbms_output.put_line(SQLERRM);
   END;

    p_clob:= XXALM_VALIDATE_INVOICES_PKG.BLOB_TO_CLOB(blobFile);
   --Guardar el archivo para el Log   
    INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Termina construccion Archivo MT940:  '||CHR(10)||p_clob,sysdate,0);
    COMMIT;
end;

-------------------------------------------------------------------------------------------


FUNCTION formatAmount (Amount IN VARCHAR2, digit IN VARCHAR2 DEFAULT ',') RETURN VARCHAR2 IS
BEGIN
RETURN substr(Amount,1,length(Amount)-2)||digit||substr(Amount,-2);
END;

-------------------------------------------------------------------------------------------

PROCEDURE createReceipts IS
  l_json            CLOB;
  l_path VARCHAR2(100);
  l_body            CLOB;
  l_response        CLOB;
  l_responseval     CLOB;
  l_user_ferp       VARCHAR2(50);
  l_pass_ferp       VARCHAR2(50);
  l_url_ferp        VARCHAR2(512);
  l_wallet          VARCHAR2(50);
  l_receipt_id      VARCHAR2(50);  
  l_json_values     APEX_JSON.t_values;
  v_error VARCHAR2(1000);
    --Report Activiti Id (Receivables Trx Id)
    l_envelope          CLOB;   
    l_xml               XMLTYPE;   
    l_soapAction        VARCHAR2(500);
    l_p_report_path     VARCHAR2(100);
    l_p_source          VARCHAR2(100);
    pReturn3        NUMBER;   
    pMsg3           VARCHAR2 (32767);
    l_clclobBI      CLOB;
    l_clobXMLBI     CLOB;
    v_len           NUMBER;   
    v_position      NUMBER;
   l_activity_id VARCHAR2(20);


BEGIN
  /*Procedmiento que itera en los registros de las tablas para creacion de cobros*/
  INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Inicia construcción de recibos',sysdate,-1);
  COMMIT;
     apex_json.free_output;
   BEGIN  
  SELECT url_cloud_bi, user_cloud, pass_cloud,wallet_path
      INTO l_url_ferp, l_user_ferp, l_pass_ferp,l_wallet
    FROM XXALM_CONFIG_T;
  FOR receipt in (SELECT * from XXALM_H2H_RECEIPTS order by receipt_number asc)LOOP

  IF(receipt.type='STAND')
  THEN
          apex_json.initialize_clob_output;
           apex_json.open_object;
                      APEX_JSON.write('ReceiptNumber', receipt.receipt_number);
                      APEX_JSON.write('BusinessUnit',trim(receipt.bunit));
                      APEX_JSON.write('ReceiptDate',to_char(to_date(receipt.r_date,'YYMMDD'),'YYYY-MM-DD'));
                      APEX_JSON.write('AccountingDate', to_char(to_date(receipt.r_date,'YYMMDD'),'YYYY-MM-DD'));
                      APEX_JSON.write('ReceiptMethod',trim(receipt.method));
                      APEX_JSON.write('Amount',to_char(to_number(receipt.amount)));
                      APEX_JSON.write('Currency',trim(receipt.moneda));
                      APEX_JSON.write('RemittanceBankAccountNumber',trim(receipt.rem_account));
                      APEX_JSON.write('RemittanceBankDepositDate', to_char(to_date(receipt.r_date,'YYMMDD'),'YYYY-MM-DD'));
                      APEX_JSON.write('CustomerSite',trim(receipt.site));
                      APEX_JSON.write('CustomerAccountNumber',trim(receipt.account_number));

            APEX_JSON.close_object;
             l_body:= apex_json.get_clob_output;
                 --dbms_output.put_line('BODY'); 
            --dbms_output.put_line(dbms_lob.substr(l_body,4000,1)); 

           apex_json.free_output;
           apex_web_service.g_request_headers.delete();
            apex_web_service.g_request_headers(1).name  := 'Content-Type';
            apex_web_service.g_request_headers(1).value := 'application/json';


            l_response := apex_web_service.make_rest_request( p_url       => l_url_ferp||'/fscmRestApi/resources/11.13.18.05/standardReceipts',
                                                            p_http_method   => 'POST',
                                                            p_body        => l_body,
                                                            p_username      => l_user_ferp,
                                                            p_password      => l_pass_ferp,
                                                            p_wallet_path   => l_wallet);
                                                          -- dbms_output.put_line(dbms_lob.substr(l_response,4000,1)); 

            IF apex_web_service.g_status_code = '201' then
                apex_json.parse(l_response);
                l_receipt_id := apex_json.get_varchar2('StandardReceiptId');
                   INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Recibo '|| receipt.receipt_number ||' creado, ID: '|| l_receipt_id  ||CHR(10)||l_body ,sysdate,0);
                   COMMIT;
            ELSE 
              INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Recibo '|| receipt.receipt_number ||' no creado.'||CHR(10)|| 'Request  '||l_body|| CHR(10)|| 'Response:'|| l_response ,sysdate,-1);
              COMMIT;

            END IF;

   END IF;
  END LOOP;
  EXCEPTION
      WHEN OTHERS THEN
       v_error:=SUBSTR(SQLERRM, 1 , 1000);
       INSERT INTO XXALM_H2H_LOG VALUES (LOG_SEQ.NEXTVAL,'Error en creacion de recibos '||v_error ,sysdate,-1);
      COMMIT;

      dbms_output.put_line(SQLERRM);  
END;
END;
-------------------------------------------------------------------------------------------

  PROCEDURE createJob
        IS
            p_script VARCHAR2(1000);
        BEGIN
            p_script := 
                'BEGIN ' ||
                 'XXALM_H2H_BS.readFile; ' ||
                 'xxalm_h2h_bs.writeMT940; ' ||
                 'xxalm_h2h_bs.createReceipts; ' ||

                'END;';

            dbms_scheduler.create_job(  
                job_name    =>  'H2H_Read',  
                job_type    =>  'PLSQL_BLOCK',  
                job_action  =>  p_script,
                repeat_interval => 'freq=daily; byhour=06; byminute=45; bysecond=0;', 
                enabled     =>  TRUE,   
                comments    => 'Parse Info from N43 to MT940 and create Receipts to fusion. Started Date: '|| to_char(TRUNC(SYSDATE)));


        END createJob;
----------------------------------------------------------------------------------

PROCEDURE getInfoAR(bankAccount IN VARCHAR2, referenceAccount IN VARCHAR2, l_BU OUT VARCHAR2, l_Site OUT VARCHAR2, l_CustAccount OUT VARCHAR2)  IS
    l_envelope          CLOB;   
    l_xml               XMLTYPE;   
    l_response          CLOB;   
    l_user_cloud        VARCHAR2(50);
    l_password_cloud    VARCHAR2(100); 
    l_url_ws_cloud_bi   VARCHAR2(512);
    l_p_report_path     VARCHAR2(200);
    l_p_source          VARCHAR2(200);

    l_user_otm          VARCHAR2(50); 
    l_password_otm      VARCHAR2(100);
    l_url_ws_otm_bi     VARCHAR2(512);

    l_url_ws_bi         VARCHAR2(512);
    l_user              VARCHAR2(50);
    l_password          VARCHAR2(100); 

    l_soapAction        VARCHAR2(50);
    l_wallet            VARCHAR2(50);

    --to decodeb64
    l_clclobBI      CLOB;
    l_clobXMLBI     CLOB;
    v_len           NUMBER;   
    v_position      NUMBER;
    pReturn3        NUMBER;   
    pMsg3           VARCHAR2 (32767);
    l_srcBI         VARCHAR2(100);
    file_xml XMLTYPE;


  BEGIN   



    SELECT  url_cloud_bi, user_cloud, pass_cloud ,wallet_path
      INTO  l_url_ws_cloud_bi, l_user_cloud, l_password_cloud, l_wallet
    FROM XXALM_CONFIG_T;

      l_url_ws_bi := l_url_ws_cloud_bi;
      l_soapAction := '/xmlpserver/services/v2/ReportService';
      l_user := l_user_cloud;
      l_password := l_password_cloud;
      l_p_report_path:='/Custom/Financials/BankStatements/XXALM_BU_BY_BANKACCOUNT_REP.xdo';
      l_p_source :='/xmlpserver/services/v2/ReportService?wsdl';

      l_envelope :=
    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v2="http://xmlns.oracle.com/oxp/service/v2"> 
        <soapenv:Header/> 
          <soapenv:Body> 
             <v2:runReport> 
                <v2:reportRequest> 
                <v2:parameterNameValues> 
                      <v2:listOfParamNameValues> 
                         <v2:item><v2:name>BANK_ACCOUNT</v2:name><v2:values><v2:item>'||bankAccount||'</v2:item></v2:values></v2:item>
                           <v2:item><v2:name>REF_ACCOUNT</v2:name><v2:values><v2:item>'||referenceAccount||'</v2:item></v2:values></v2:item>

                      </v2:listOfParamNameValues> 
                   </v2:parameterNameValues> 
                   <v2:reportAbsolutePath>'||l_p_report_path||'</v2:reportAbsolutePath> 
                </v2:reportRequest>
                  <v2:userID>'||l_user||'</v2:userID> 
                  <v2:password>'||l_password||'</v2:password>
             </v2:runReport> 
          </soapenv:Body> 
        </soapenv:Envelope>'; 

    --DBMS_OUTPUT.put_line('l_envelope: ' || l_envelope ); 
    apex_web_service.g_request_headers.delete(); 
    l_xml := APEX_WEB_SERVICE.make_request( p_url         => l_url_ws_bi||l_p_source,
                                            p_action      => l_soapAction,--'/xmlpserver/services/v2/ReportService',
                                            p_envelope    => l_envelope,
                                            p_username    => l_user,
                                            p_password    => l_password,
                                            p_wallet_path => l_wallet,
                                            p_transfer_timeout => 480);   



    l_response :=  apex_web_service.PARSE_XML_CLOB( p_xml   => l_xml, 
                                                    p_xpath => '//runReportResponse/runReportReturn/reportBytes',  
                                                    p_ns    => 'xmlns="http://xmlns.oracle.com/oxp/service/v2"' );  



    v_len := DBMS_LOB.getlength (l_response);

        IF (DBMS_LOB.isopen (l_response) != 1) THEN   
            DBMS_LOB.open (l_response, 0);   
        END IF; 

        v_position := INSTR (l_response, '>');   


        l_clclobBI   := REPLACE(REPLACE (SUBSTR (l_response, v_position + 1, v_len),'</reportBytes>',''),'"','');

    XXALM_VALIDATE_INVOICES_PKG.decodeClobBase642Clob(l_clclobBI,l_clobXMLBI,pReturn3,pMsg3);


    BEGIN

      select extractvalue(xmltype(l_clobXMLBI), 'DATA_DS/INFO/BU'),
             extractvalue(xmltype(l_clobXMLBI), 'DATA_DS/INFO/ACCOUNTNUMBER'),
             extractvalue(xmltype(l_clobXMLBI), 'DATA_DS/INFO/SITENUMBER')  INTO l_BU, l_CustAccount, l_Site
      from dual;




EXCEPTION
      WHEN OTHERS THEN
      dbms_output.put_line(SQLERRM); 
      l_BU:= '';
      l_CustAccount := '';
      l_Site := '';
      END;


END;

  END XXALM_H2H_BS;