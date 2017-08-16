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
  CALL GETARG(2, constantsfile)
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
  INTEGER :: hail_opt  ! RAS
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
! for radiation connecting
  INTEGER ::                                           &
                                                        has_reqc, &
                                                        has_reqi, &
                                                        has_reqs
  REAL, DIMENSION(ims:ime, kms:kme, jms:jme) ::                   &
                                                        re_cloud, &
                                                          re_ice, &
                                                         re_snow
!+---+-----------------------------------------------------------------+
  REAL, DIMENSION(ims:ime, kms:kme, jms:jme) ::     &  ! GT
                                                       refl_10cm
!+---+-----------------------------------------------------------------+

  REAL, DIMENSION( ims:ime , jms:jme ) ::                snow, &
                                                         snowncv
  REAL, DIMENSION( ims:ime , jms:jme ) ::             graupel, &
                                                      graupelncv

#ifdef WRF_CHEM
  REAL, DIMENSION( ims:ime , kms:kme, jms:jme )  :: &
                                                      rainprod,   &
                                                      evapprod
#endif

  LOGICAL :: diagflag
  INTEGER :: do_radar_ref

  INTEGER :: unitno
  CHARACTER(256) :: datafile
  CHARACTER(256) :: constantsfile

!  read(unitno)                                         &
!    qc0, qck1, pidnc,                                  & 
!    bvtr1,bvtr2,bvtr3,bvtr4,g1pbr,                     &
!    g3pbr,g4pbr,g5pbro2,pvtr,eacrr,pacrr,              &
!    bvtr6,g6pbr,                                       &
!    precr1,precr2,roqimax,bvts1,                       &
!    bvts2,bvts3,bvts4,g1pbs,g3pbs,g4pbs,               &
!    n0g,avtg,bvtg,deng,lamdagmax,                      & !RAS13.3 - set these in wsm6init
!    g5pbso2,pvts,pacrs,precs1,precs2,pidn0r,           &
!    pidn0s,xlv1,pacrc,pi,                              &
!    bvtg1,bvtg2,bvtg3,bvtg4,g1pbg,                     &
!    g3pbg,g4pbg,g5pbgo2,pvtg,pacrg,                    &
!    precg1,precg2,pidn0g,                              &
!    rslopermax,rslopesmax,rslopegmax,                  &
!    rsloperbmax,rslopesbmax,rslopegbmax,               &
!    rsloper2max,rslopes2max,rslopeg2max,               &
!    rsloper3max,rslopes3max,rslopeg3max

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
    ,has_reqc, has_reqi, has_reqs                      &  ! for radiation
#ifdef WRF_CHEM
    ,evapprod, rainprod                                &
#endif
    ,re_cloud, re_ice,   re_snow                          ! for radiation   
  close(unitno)

  print *, 'In wsm6_microservice()'
                 
!                 print *, 'Wrote th'
!                 print *,' max th = ',maxval(th),' at ',maxloc(th)
!                 print *,' min th = ',minval(th),' at ',minloc(th)
!                 
!                 print *, 'Wrote qc'
!                 print *,' max qc = ',maxval(qc),' at ',maxloc(qc)
!                 print *,' min qc = ',minval(qc),' at ',minloc(qc)
!                 
!                 print *, 'Wrote q'
!                 print *,' max q = ',maxval(q),' at ',maxloc(q)
!                 print *,' min q = ',minval(q),' at ',minloc(q)
!                 
!                 print *, 'Wrote den'
!                 print *,' max den = ',maxval(den),' at ',maxloc(den)
!                 print *,' min den = ',minval(den),' at ',minloc(den)
!                 
!                 print *, 'Wrote rain'
!                 print *,' max rain = ',maxval(rain),' at ',maxloc(rain)
!                 print *,' min rain = ',minval(rain),' at ',minloc(rain)
!                 
!                 print *, 'Wrote delz'
!                 print *,' max delz = ',maxval(delz),' at ',maxloc(delz)
!                 print *,' min delz = ',minval(delz),' at ',minloc(delz)
!                 
!                  print *,' delt = ',delt
!                 
!                  print *,' g = ',g
!                 
!                  print *,' cpd = ',cpd
!                 
!                  print *,' cpv = ',cpv
!                 
!                  print *,' t0c = ',t0c
!                 
!                  print *,' den0 = ',den0
!                 
!                  print *,' rd = ',rd
!                 
!                  print *,' rv = ',rv
!                 
!                  print *,' ep1 = ',ep1
!                
!                  print *,' ep2 = ',ep2
!                
!                  print *,' qmin = ',qmin
!                 
!                  print *,' XLS = ',XLS
!                 
!                  print *,' XLV0 = ',XLV0
!                 
!                  print *,' XLF0 = ',XLF0
!                 
!                  print *,' cliq = ',cliq
!                 
!                  print *,' cice = ',cice
!                 
!                  print *,' psat = ',psat
!                 
!                  print *,' denr = ',denr
!                 
!                 print *, 'Wrote rain'
!                 
!                 print *, 'Wrote rainncv'
!                 
!                 print *, 'Wrote sr'
!                 
!                 print *, 'Wrote snow'
!                 print *,' max snow = ',maxval(snow),' at ',maxloc(snow)
!                 print *,' min snow  = ',minval(snow),' at ',minloc(snow)
!                 
!                 print *, 'Wrote snowncv'
!                 
!                 print *, 'Wrote graupel'
!                 
!                 print *, 'Wrote graupelncv'

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
    ,REFL_10CM=refl_10cm                               &  ! added for radar reflectivity
    ,diagflag=diagflag                                 &  ! added for radar reflectivity
    ,do_radar_ref=do_radar_ref                         &  ! added for radar reflectivity
    ,GRAUPEL=graupel ,GRAUPELNCV=graupelncv          &
    ,has_reqc=has_reqc                                 &  ! for radiation +
    ,has_reqi=has_reqi                                 &
    ,has_reqs=has_reqs                                 &
    ,re_cloud=re_cloud                                 &
    ,re_ice=re_ice                                     &
    ,re_snow=re_snow                                   &  ! for radiation -  
    ,IDS=ids,IDE=ide, JDS=jds,JDE=jde, KDS=kds,KDE=kde &
    ,IMS=ims,IME=ime, JMS=jms,JME=jme, KMS=kms,KME=kme &
    ,ITS=its,ITE=ite, JTS=jts,JTE=jte, KTS=kts,KTE=kte &
#ifdef WRF_CHEM
    ,EVAPPROD=evapprod,RAINPROD=rainprod               &
#endif
    )

  open (unitno, file=trim(datafile)//'.out', form="unformatted", action='write')
  write(unitno)                                         &
     th, q, qc, qr, qi, qs, qg,                         &
#ifdef WRF_CHEM
     rainprod, evapprod                                 &
#endif
     rain, rainncv, sr,                                 &
     re_cloud, re_ice, re_snow,                         &
     refl_10cm,                                         &
     snow, snowncv,                                     &
     graupel, graupelncv
  close(unitno)   


  
end subroutine wsm6_microservice
