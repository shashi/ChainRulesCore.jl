cool(x) = x + 1
cool(x, y) = x + y + 1

_second(t) = Base.tuple_type_head(Base.tuple_type_tail(t))

# a rule we define so we can test rules
dummy_identity(x) = x
@scalar_rule(dummy_identity(x), One())

@testset "rules" begin
    @testset "frule and rrule" begin
        @test frule(cool, 1) === nothing
        @test frule(cool, 1; iscool=true) === nothing
        @test rrule(cool, 1) === nothing
        @test rrule(cool, 1; iscool=true) === nothing

        ChainRulesCore.@scalar_rule(Main.cool(x), one(x))
        @test hasmethod(rrule, Tuple{typeof(cool),Number})
        ChainRulesCore.@scalar_rule(Main.cool(x::String), "wow such dfdx")
        @test hasmethod(rrule, Tuple{typeof(cool),String})
        # Ensure those are the *only* methods that have been defined
        cool_methods = Set(m.sig for m in methods(rrule) if _second(m.sig) == typeof(cool))
        only_methods = Set([Tuple{typeof(rrule),typeof(cool),Number},
                            Tuple{typeof(rrule),typeof(cool),String}])
        @test cool_methods == only_methods

        frx, fr = frule(cool, 1)
        @test frx == 2
        @test fr(1) == 1
        rrx, rr = rrule(cool, 1)
        @test rrx == 2
        @test rr(1) == 1
    end
    @testset "iterating and indexing rules" begin
        _, rule = frule(dummy_identity, 1)
        i = 0
        for r in rule
            @test r === rule
            i += 1
        end
        @test i == 1  # rules only iterate once, yielding themselves
        @test rule[1] == rule
        @test_throws BoundsError rule[2]
    end
end
