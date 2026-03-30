package com.hospital.moblie.repository;
import com.hospital.moblie.model.User;
import com.hospital.moblie.model.Role;
import java.util.List;
import com.hospital.moblie.model.UserStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByRole(Role role);
    List<User> findByStatus(UserStatus status);
    boolean existsByEmailAndIdNot(String email, Long id);
    boolean existsByEmail(String email);
    Optional<User> findByEmail(String email);

}