package com.example.demo.controller;

import com.example.demo.model.User;
import com.example.demo.repo.UserRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/users")
public class UserController {
  private final UserRepository repo;
  public UserController(UserRepository repo) { this.repo = repo; }

  @GetMapping
  public List<User> all() { return repo.findAll(); }

  @PostMapping
  public User create(@RequestBody User u) { return repo.save(u); }

  @GetMapping("/{id}")
  public User get(@PathVariable Long id) { return repo.findById(id).orElse(null); }
}
