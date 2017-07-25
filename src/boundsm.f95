module module_boundsm
#ifdef MPI
    use communication_helper_real
#endif
contains

#ifdef NESTED_LES
subroutine boundsm(n,km,jm,sm,im)
   use common_sn ! create_new_include_statements() line 102
    implicit none
    integer, intent(In) :: n
#else
subroutine boundsm(km,jm,sm,im)
   use common_sn ! create_new_include_statements() line 102
    implicit none
#endif

    integer, intent(In) :: im
    integer, intent(In) :: jm
    integer, intent(In) :: km
    real(kind=4), dimension(-1:ip+1,-1:jp+1,0:kp+1) , intent(InOut) :: sm
    integer :: i, j, k
!
! =================================
#ifdef MPI
    if (isTopRow(procPerRow) .or. isBottomRow(procPerRow)) then
#endif
        do k = 0,km+1
            do j = -1,jm+1
#ifdef MPI
                if (isTopRow(procPerRow)) then
#endif
                    sm(   0,j,k) = sm(1 ,j,k) ! GR: Why not sm(-1,,) = sm(0,,)?
#ifdef MPI
                else
#endif
                    sm(im+1,j,k) = sm(im,j,k)
#ifdef MPI
                end if
#endif
            end do
        end do
#ifdef MPI
    end if
#endif
! --side flow condition
#ifdef MPI
    if (isLeftmostColumn(procPerRow) .or. isRightmostColumn(procPerRow)) then
#endif
        do k = 0,km+1
            do i = 0,im+1
#ifdef MPI
                if (isRightmostColumn(procPerRow)) then
#endif
                    sm(i,jm+1,k) = sm(i,jm  ,k)
#ifdef MPI
                else
#endif
                    sm(i,0,k) = sm(i,1   ,k) ! GR: Why not sm(,-1,) = sm(,0,)?
#ifdef MPI
                end if
#endif
            end do
        end do
#ifdef MPI
    end if
#endif
! --underground condition
    do j = -1,jm+1
        do i = 0,im+1
            sm(i,j,   0) = -sm(i,j, 1)
            sm(i,j,km+1) = sm(i,j,km)
        end do
    end do
#ifdef MPI
! --halo exchanges
#ifdef NESTED_LES
!   if (syncTicks == 0  .and. n > 2) then
   if (syncTicks == 0) then
#endif
    call exchangeRealHalos(sm, procPerRow, neighbours, 2, 1, 2, 1)
#ifdef NESTED_LES
   end if
#endif
#endif
end subroutine boundsm

end module module_boundsm
