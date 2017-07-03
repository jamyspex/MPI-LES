module module_feedbfm

contains

subroutine feedbfm(km,jm,im,amask1,bmask1,cmask1,dmask1,zbm,z2,dzn)
    use common_sn ! create_new_include_statements() line 102
    implicit none
    real(kind=4), dimension(0:ip+1,0:jp+1,0:kp+1) , intent(Out) :: amask1
    real(kind=4), dimension(-1:ip+1,0:jp+1,0:kp+1) , intent(Out) :: bmask1
    real(kind=4), dimension(0:ip+1,-1:jp+1,0:kp+1) , intent(Out) :: cmask1
    real(kind=4), dimension(0:ip+1,0:jp+1,0:kp+1) , intent(Out) :: dmask1
    real(kind=4), dimension(-1:kp+2) , intent(In) :: dzn
    integer, intent(In) :: im
    integer, intent(In) :: jm
    integer, intent(In) :: km
    real(kind=4), dimension(0:kp+2) , intent(In) :: z2
    real(kind=4), dimension(-1:ipmax+1,-1:jpmax+1) , intent(InOut) :: zbm
    integer :: i, j, k
    real(kind=4), dimension(-1:ipmax+1,-1:jpmax+1) :: dsm,dem


!
!    print *, 'Urban model'
! -------Urban model----------
    do k = 1,km
        do j = 1,jm
            do i = 1,im
                amask1(i,j,k) = 1.
                bmask1(i,j,k) = 0.
                cmask1(i,j,k) = 0.
                dmask1(i,j,k) = 0.
            end do
        end do
    end do


    do j=1,jpmax
      do i=1,ipmax
            zbm(i,j)=0.
      end do
    end do



#ifdef MPI
!    if (isMaster()) then
#endif
        print*, 'zbm sum - file getting read'
        !      print *, 'open GIS/Tokyo_20mgrid.txt'
        ! WV: the problem with this is that this input file expects the grid to be 150 x 150, because otherwise zbm segfaults!

!--

      if (isMaster()) then
        open(70,file=datafile,form='formatted',status='unknown')
           do j=1,jpmax
              do i=1,ipmax
                 read(70,*) zbm(i,j)
              end do
           end do
        close(70)
      end if !for imaster
      call distributeZBM(zbm, ip, jp, ipmax, jpmax, procPerRow)

! print *, 'assign amask'
      do j = 1,jm
          do i = 1,im
              do k = 1,km
                  if(zbm(i,j) > z2(k)+0.5*dzn(k)) then
                      amask1(i,j,k) = 0.0
                  end if
              end do
          end do
      end do

#ifdef MPI
!    end if
!    call distributeZBM(zbm, ip, jp, ipmax, jpmax, procPerRow)
#endif

! -----------------------------------------------------------------------
!print *, 'assign bcd masks'
    do k = 1,km
        do j = 1,jm
            do i = 1,im
                if(amask1(i,j,k) == 0.0) then
                    bmask1(i,j,k) = 1.0
                    cmask1(i,j,k) = 1.0
                    dmask1(i,j,k) = 1.0
                end if
            end do
        end do
    end do
#ifdef MPI
    call exchangeRealHalos(amask1, procPerRow, neighbours, 1, 1, 1, 1)
    call exchangeRealHalos(bmask1, procPerRow, neighbours, 1, 1, 2, 1)
    call exchangeRealHalos(cmask1, procPerRow, neighbours, 2, 1, 1, 1)
    call exchangeRealHalos(dmask1, procPerRow, neighbours, 1, 1, 1, 1)
#endif
!
end subroutine feedbfm

end module module_feedbfm
