@connector function MagneticPort(;name, complex=false)
    if complex 
        V_m, Phi = @variables V_m(t)::Complex Phi(t)::Complex
    else
        V_m, Phi = @variables V_m(t) Phi(t)
    end
    ODESystem(Equation[], t, [V_m, Phi], [], name=name, defaults=Dict(V_m=>0.0, Phi=>0.0))
end

function ModelingToolkit.connect(::Type{<:MagneticPort}, ps...)
    eqs = [
           0 ~ sum(p->p.Phi, ps) # Gauss's law for magnetism
          ]

    for i in 1:length(ps)-1
        push!(eqs, ps[i].V_m ~ ps[i+1].V_m)
    end

    return eqs
end

const PositiveMagneticPort = MagneticPort
const NegativeMagneticPort = MagneticPort

function TwoPortElementary(;name, complex=false)
    @named port_p = PositiveMagneticPort(;complex=complex)
    @named port_n = NegativeMagneticPort(;complex=complex)
    ODESystem(Equation[], t, [], [], systems=[port_p, port_n], name=name)
end

function TwoPortExtended(;name, complex=false)
    @named two_port_elementary = TwoPortElementary(complex=complex)
    @unpack port_p, port_n = two_port_elementary
    @variables V_m(t) Phi(t)
    eqs = [
        V_m ~ port_p.V_m - port_n.V_m,
        Phi ~ port_p.Phi,
    ]
    extend(ODESystem(eqs, t, [V_m, Phi], [], systems=[port_p, port_n], name=name), two_port_elementary)
end

function TwoPort(;name, complex=false)
    @named two_port_extended = TwoPortExtended(;complex=complex)
    @unpack port_p, port_n = two_port_extended
    eqs = [
        0 ~ port_p.Phi + port_n.Phi,
    ]
    extend(ODESystem(eqs, t, [], [], systems=[port_p, port_n], name=name), two_port_extended)
end

function AbsoluteSensor(;name)
    @variables omega
    @named port = PositiveMagneticPort(;complex=true)
    eqs = [
        D(port.reference.gamma) ~ omega,
        port.Phi ~ Complex(0);
    ]
    ODESystem(eqs, t, [omega, port.Phi, port.reference.gamma], [], systems=[], name=name)
end