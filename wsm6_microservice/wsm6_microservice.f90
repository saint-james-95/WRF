program get_dimensions
  IMPLICIT NONE

  INTEGER                        ::   ids,ide, jds,jde, kds,kde , &
                                      ims,ime, jms,jme, kms,kme , &
                                      its,ite, jts,jte, kts,kte
  CHARACTER(256) :: datafile
  CHARACTER(256) :: constantsfile
  INTEGER :: unitno = 31
   
  print *, 'in get_dimensions'
  CALL GETARG(1, datafile)
  constantsfile = "/home/keirouz/WRF/WRFV3_Serial/wsm6_microservice/wsm6_constants"
  open (unitno, file=trim(datafile), form="unformatted", action='read')

  read(unitno)                                         &
     ids,ide, jds,jde, kds,kde                         &
    ,ims,ime, jms,jme, kms,kme                         &
    ,its,ite, jts,jte, kts,kte                         
  
  CALL wsm6_microservice (ids,ide, jds,jde, kds,kde               &
                         ,ims,ime, jms,jme, kms,kme               &
                         ,its,ite, jts,jte, kts,kte               &
                         ,unitno, datafile, constantsfile)

end program get_dimensions

subroutine wsm6_microservice (ids,ide, jds,jde, kds,kde           &
                             ,ims,ime, jms,jme, kms,kme           &
                             ,its,ite, jts,jte, kts,kte           &
                             ,unitno, datafile, constantsfile)
  USE module_mp_wsm6
  
  IMPLICIT NONE

  INTEGER,      INTENT(IN   )    ::   ids,ide, jds,jde, kds,kde , &
                                      ims,ime, jms,jme, kms,kme , &
                                      its,ite, jts,jte, kts,kte

  REAL :: den0_init,denr_init,dens,cl,cpv_init
  INTEGER :: hail_opt  
  LOGICAL :: allowed_to_read


  REAL, DIMENSION( ims:ime , kms:kme , jms:jme ) ::               &
                                                             th,  &
                                                              q,  &
                                                              qc, &
                                                              qi, &
                                                              qr, &
                                                              qs, &
                                                              qg
  REAL, DIMENSION( ims:ime , kms:kme , jms:jme )  ::              &
                                                             den, &
                                                             pii, &
                                                               p, &
                                                            delz
  REAL  ::                                                  delt, &
                                                               g, &
                                                              rd, &
                                                              rv, &
                                                             t0c, &
                                                            den0, &
                                                             cpd, &
                                                             cpv, &
                                                             ep1, &
                                                             ep2, &
                                                            qmin, &
                                                             XLS, &
                                                            XLV0, &
                                                            XLF0, &
                                                            cliq, &
                                                            cice, &
                                                            psat, &
                                                            denr
  REAL, DIMENSION( ims:ime , jms:jme ) ::                   rain, &
                                                         rainncv, &
                                                              sr

  INTEGER ::                                           &
                                                        has_reqc, &
                                                        has_reqi, &
                                                        has_reqs
  REAL, DIMENSION(ims:ime, kms:kme, jms:jme) ::                   &
                                                        re_cloud, &
                                                          re_ice, &
                                                         re_snow

  REAL, DIMENSION(ims:ime, kms:kme, jms:jme) ::     &  
                                                       refl_10cm


  REAL, DIMENSION( ims:ime , jms:jme ) ::                snow, &
                                                         snowncv
  REAL, DIMENSION( ims:ime , jms:jme ) ::             graupel, &
                                                      graupelncv


  LOGICAL :: diagflag
  INTEGER :: do_radar_ref

  INTEGER :: unitno
  CHARACTER(256) :: datafile
  CHARACTER(256) :: constantsfile



















  open (32, file=trim(constantsfile), form="unformatted", action='read')
  read(32) den0_init,denr_init,dens,cl,cpv_init,hail_opt,allowed_to_read
  close(32)
  CALL wsm6init(den0_init,denr_init,dens,cl,cpv_init,hail_opt,allowed_to_read)
  

  read(unitno)                                         &
     th, q, qc, qr, qi, qs, qg                         &
    ,den, pii, p, delz                                 &
    ,delt,g, cpd, cpv, rd, rv, t0c                     &
    ,ep1, ep2, qmin                                    &
    ,XLS, XLV0, XLF0, den0, denr                       &
    ,cliq,cice,psat                                    &
    ,rain, rainncv                                     &
    ,snow, snowncv                                     &
    ,sr                                                &
    ,refl_10cm, diagflag, do_radar_ref                 &
    ,graupel, graupelncv                               &
    ,has_reqc, has_reqi, has_reqs                      &  
    ,re_cloud, re_ice,   re_snow                          
  close(unitno)

  print *, 'In wsm6_microservice()'
                 












































































  CALL wsm6(                                           &
    TH=th                                              &
    ,Q=q                                         &
    ,QC=qc                                        &
    ,QR=qr                                        &
    ,QI=qi                                        &
    ,QS=qs                                        &
    ,QG=qg                                        &
    ,DEN=den,PII=pii,P=p,DELZ=delz                  &
    ,DELT=delt,G=g,CPD=cpd,CPV=cpv                        &
    ,RD=rd,RV=rv,T0C=t0c                           &
    ,EP1=ep1, EP2=ep2, QMIN=qmin                  &
    ,XLS=xls, XLV0=xlv0, XLF0=xlf0                       &
    ,DEN0=den0, DENR=denr                       &
    ,CLIQ=cliq,CICE=cice,PSAT=psat                     &
    ,RAIN=rain ,RAINNCV=rainncv                      &
    ,SNOW=snow ,SNOWNCV=snowncv                      &
    ,SR=sr                                             &
    ,REFL_10CM=refl_10cm                               &  
    ,diagflag=diagflag                                 &  
    ,do_radar_ref=do_radar_ref                         &  
    ,GRAUPEL=graupel ,GRAUPELNCV=graupelncv          &
    ,has_reqc=has_reqc                                 &  
    ,has_reqi=has_reqi                                 &
    ,has_reqs=has_reqs                                 &
    ,re_cloud=re_cloud                                 &
    ,re_ice=re_ice                                     &
    ,re_snow=re_snow                                   &  
    ,IDS=ids,IDE=ide, JDS=jds,JDE=jde, KDS=kds,KDE=kde &
    ,IMS=ims,IME=ime, JMS=jms,JME=jme, KMS=kms,KME=kme &
    ,ITS=its,ITE=ite, JTS=jts,JTE=jte, KTS=kts,KTE=kte &
    )

  open (unitno, file=trim(datafile)//'.out', form="unformatted", action='write')
  write(unitno)                                         &
     th, q, qc, qr, qi, qs, qg,                         &
     rain, rainncv, sr,                                 &
     re_cloud, re_ice, re_snow,                         &
     refl_10cm,                                         &
     snow, snowncv,                                     &
     graupel, graupelncv
  close(unitno)   


  
end subroutine wsm6_microservice
